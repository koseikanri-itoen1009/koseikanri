CREATE OR REPLACE PACKAGE xxwsh600001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh600001c(spec)
 * Description      : 自動配車配送計画作成処理
 * MD.050           : 配車配送計画 T_MD050_BPO_600
 * MD.070           : 自動配車配送計画作成処理 T_MD070_BPO_60B
 * Version          : 1.22
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
 *  2008/03/11    1.0   Y.Kanami         新規作成
 *  2008/06/26    1.1  Oracle D.Sugahara ST障害 #297対応 *
 *  2008/07/02    1.2  Oracle M.Hokkanji ST障害 #321,351対応 *
 *  2008/07/10    1.3  Oracle M.Hokkanji TE080指摘03対応、ヘッダ積載率再計算対応
 *  2008/07/14    1.4  Oracle 山根一浩   仕様変更No.95対応
 *  2008/08/04    1.5  Oracle M.Hokkanji 結合再テスト不具合対応(400TE080_159原因2),ST513対応
 *  2008/08/06    1.6  Oracle M.Hokkanji ST不具合493対応
 *  2008/08/08    1.7  Oracle M.Hokkanji ST不具合510対応、内部変更173対応
 *  2008/09/05    1.8  Oracle A.Shiina   PT 6-1_27 指摘41-2 対応
 *  2008/10/01    1.9  Oracle H.Itou     PT 6-1_27 指摘18 対応
 *  2008/10/16    1.10 Oracle H.Itou     T_S_625,統合テスト指摘369
 *  2008/10/24    1.11 Oracle H.Itou     T_TE080_BPO_600指摘26
 *  2008/10/30    1.12 Oracle H.Itou     統合テスト指摘526
 *  2008/11/19    1.13 Oracle H.Itou     統合テスト指摘666
 *  2008/11/29    1.14 Oracle MIYATA     ロック対応 NO WAIT　を削除してWAITにする
 *  2008/12/02    1.15 Oracle H.Itou     本番障害#220対応
 *  2008/12/07    1.16 SCS    D.Sugahara 本番障害#524暫定対応
 *  2009/01/05    1.17 SCS    H.Itou     本番障害#879対応
 *  2009/01/08    1.18 SCS    H.Itou     本番障害#558,599対応
 *  2009/01/27    1.19 SCS    H.Itou     本番障害#1028対応
 *  2009/02/27    1.20 SCS    M.Hokkanji 本番障害#1228対応
 *  2009/04/17    1.21 SCS    H.Itou     本番障害#1398対応
 *  2009/04/20    1.22 SCS    H.Itou     本番障害#1398再対応
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
    iv_forwarder_id         IN  VARCHAR2,         -- 10.運送業者
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
    iv_instruction_dept     IN  VARCHAR2          -- 11.指示部署
-- 2009/01/27 H.Itou Add End
  );
END xxwsh600001c;
/
