CREATE OR REPLACE PACKAGE xxpo940003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940003c(spec)
 * Description      : ロット在庫情報抽出処理
 * MD.050           : 生産物流共通                  T_MD050_BPO_940
 * MD.070           : ロット在庫情報抽出処理        T_MD070_BPO_94C
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
 *  2008/07/01    1.0   Oracle 大橋 孝郎 初回作成
 *  2008/08/01    1.1   Oracle 吉田 夏樹 ST不具合対応&PT対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  --   エラー・メッセージ  --# 固定 #
    retcode                 OUT NOCOPY VARCHAR2,  --   リターン・コード    --# 固定 #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.処理区分          (必須)
    iv_wf_class          IN            VARCHAR2,  --  2.対象              (必須)
    iv_wf_notification   IN            VARCHAR2,  --  3.宛先              (必須)
    iv_prod_class        IN            VARCHAR2,  --  4.商品区分          (必須)
    iv_item_class        IN            VARCHAR2,  --  5.品目区分          (必須)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.代表倉庫区分      (任意)
    iv_whse              IN            VARCHAR2,  --  7.倉庫              (任意)
    iv_vendor_id         IN            VARCHAR2,  --  8.取引先            (任意)
    iv_item_no           IN            VARCHAR2,  --  9.品目              (任意)
    iv_lot_no            IN            VARCHAR2,  -- 10.ロット            (任意)
    iv_Manufacture_date  IN            VARCHAR2,  -- 11.製造日            (任意)
    iv_expiration_date   IN            VARCHAR2,  -- 12.賞味期限          (任意)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.固有記号          (任意)
    iv_mf_factory        IN            VARCHAR2,  -- 14.製造工場          (任意)
    iv_mf_lot            IN            VARCHAR2,  -- 15.製造ロット        (任意)
    iv_home              IN            VARCHAR2,  -- 16.産地              (任意)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (任意)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (任意)
    iv_sec_class         IN            VARCHAR2   -- 19.セキュリティ区分  (必須)
    );
END xxpo940003c;
/
