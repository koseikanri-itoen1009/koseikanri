create or replace
PACKAGE xxwsh600006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH600006C(spec)
 * Description      : 自動配車配送計画作成処理ロック対応
 * MD.050           : 配車配送計画 T_MD050_BPO_600
 * MD.070           : 自動配車配送計画作成処理 T_MD070_BPO_60B
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  release_lock         ロック解除関数
 *  main                 メイン関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/29   1.0   T.MIYATA    b    初回作成
 *  2008/12/20   1.1   M.Hokkanji       本番障害#738
 *  2009/01/16   1.2   M.Nomura         本番障害#900
 *  2009/01/27   1.3   H.Itou           本番障害#1028
 *****************************************************************************************/
--
  -- メイン関数
  PROCEDURE main(
        errbuf                  OUT NOCOPY VARCHAR2,  --  エラー・メッセージ
        retcode                 OUT NOCOPY VARCHAR2,  --  リターン・コード
        iv_prod_class           IN  VARCHAR2,         --  1.商品区分
        iv_shipping_biz_type    IN  VARCHAR2,         --  2.処理種別
        iv_block_1              IN  VARCHAR2,         --  3.ブロック1
        iv_block_2              IN  VARCHAR2,         --  4.ブロック2
        iv_block_3              IN  VARCHAR2,         --  5.ブロック3
        iv_storage_code         IN  VARCHAR2,         --  6.出庫元
        iv_transaction_type_id  IN  VARCHAR2,         --  7.出庫形態ID
        iv_date_from            IN  VARCHAR2,         --  8.出庫日From
        iv_date_to              IN  VARCHAR2,         --  9.出庫日To
        iv_forwarder_id         IN  VARCHAR2,         -- 10.運送業者ID
-- Ver1.3 H.Itou Add Start 本番障害#1028対応
        iv_instruction_dept     IN  VARCHAR2          -- 11.指示部署
-- Ver1.3 H.Itou Add End
    );
END xxwsh600006c;
/
