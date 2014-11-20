CREATE OR REPLACE PACKAGE xxwsh600001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600001c(spec)
 * Description      : 自動配車配送計画作成処理
 * MD.050           : 配車配送計画 T_MD050_BPO_600
 * MD.070           : 自動配車配送計画作成処理 T_MD070_BPO_60B
 * Version          : 1.0
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
 *  <作成日>      1.0   Y.Kanami         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  -- エラーメッセージ #固定#
    retcode                 OUT NOCOPY VARCHAR2,  -- エラーコード     #固定#
    iv_prod_class           IN  VARCHAR2,         --  1.商品区分
    iv_shipping_biz_type    IN  VARCHAR2,         --  2.処理種別
    iv_block_1              IN  VARCHAR2,         --  3.ブロック1
    iv_block_2              IN  VARCHAR2,         --  4.ブロック2
    iv_block_3              IN  VARCHAR2,         --  5.ブロック3
    iv_storage_code         IN  VARCHAR2,         --  6.出庫元
    iv_transaction_type_id  IN  VARCHAR2,         --  7.出庫形態
    iv_date_from            IN  VARCHAR2,         --  8.出庫日From
    iv_date_to              IN  VARCHAR2,         --  9.出庫日To
    iv_forwarder_id         IN  VARCHAR2          -- 10.運送業者
  );
END xxwsh600001c;
/
