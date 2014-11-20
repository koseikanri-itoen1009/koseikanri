CREATE OR REPLACE PACKAGE xxwsh400004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400004c(spec)
 * Description      : 出荷依頼締め関数
 * MD.050           : 出荷依頼               T_MD050_BPO_401
 * MD.070           : 出荷依頼締め関数       T_MD070_BPO_40E
 * Version          : 1.15
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  ship_tightening      出荷依頼締め関数
 *
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/4/8      1.0   R.Matusita        初回作成
 *  2008/5/19     1.1   Oracle 上原正好 内部変更要求#80対応 パラメータ「拠点」追加
 *  2008/5/21     1.2   Oracle 上原正好 結合テストバグ修正
 *                                      パラメータ「締め処理区分」がNULLのときは'1'(初回締め)とする
 *                                      指示部署取得処理SQL修正(顧客情報VIEWを参照しない)
 *  2008/6/06     1.3   Oracle 石渡賢和 リードタイムチェック時の判定を変更
 *  2008/6/27     1.4   Oracle 上原正好 内部課題56対応 呼出元が画面の場合にも締め管理アドオン登録
 *  2008/6/30     1.5   Oracle 北寒寺正夫 ST不具合対応#326
 *  2008/7/01     1.6   Oracle 北寒寺正夫 ST不具合対応#338
 *  2008/08/05    1.7   Oracle 山根一浩 出荷追加_5対応
 *  2008/10/10    1.8   Oracle 伊藤ひとみ 統合テスト指摘239対応
 *  2008/10/28    1.9   Oracle 伊藤ひとみ 統合テスト指摘141対応
 *  2008/11/14   1.10  SCS    伊藤ひとみ 統合テスト指摘650対応
 *  2008/12/01   1.11  SCS    菅原大輔   本番指摘253対応（暫定） 
 *  2008/12/07   1.12  SCS    菅原大輔   本番#386
 *  2008/12/17   1.13  SCS    上原正好   本番#81
 *  2008/12/17   1.13  SCS    福田       APP-XXWSH-11204エラー発生時に即時終了しないようにする
 *  2008/12/23   1.14  SCS    上原       本番#81 再締め処理時の抽出条件にリードタイムを追加
 *  2009/01/16   1.15  SCS    菅原大輔   本番#1009 ロックセッション切断対応 
 *****************************************************************************************/
--
  -- 出荷依頼締め関数
  PROCEDURE ship_tightening(
    in_order_type_id         IN  NUMBER    DEFAULT NULL, -- 出庫形態ID
    iv_deliver_from          IN  VARCHAR2  DEFAULT NULL, -- 出荷元
    iv_sales_base            IN  VARCHAR2  DEFAULT NULL, -- 拠点
    iv_sales_base_category   IN  VARCHAR2  DEFAULT NULL, -- 拠点カテゴリ
    in_lead_time_day         IN  NUMBER    DEFAULT NULL, -- 生産物流LT
    id_schedule_ship_date    IN  DATE      DEFAULT NULL, -- 出庫日
    iv_base_record_class     IN  VARCHAR2  DEFAULT NULL, -- 基準レコード区分
    iv_request_no            IN  VARCHAR2  DEFAULT NULL, -- 依頼No
    iv_tighten_class         IN  VARCHAR2  DEFAULT NULL, -- 締め処理区分
    in_tightening_program_id IN  NUMBER    DEFAULT NULL, -- 締めコンカレントID
    iv_tightening_status_chk_class
                             IN  VARCHAR2,               -- 締めステータスチェック区分
    iv_callfrom_flg          IN  VARCHAR2,               -- 呼出元フラグ
    iv_prod_class            IN  VARCHAR2  DEFAULT NULL, -- 商品区分
    iv_instruction_dept      IN  VARCHAR2  DEFAULT NULL, -- 部署
    ov_errbuf                OUT NOCOPY  VARCHAR2,       -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY  VARCHAR2,       -- リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY  VARCHAR2        -- ユーザー・エラー・メッセージ --# 固定 #
    );    
END xxwsh400004c;
/
