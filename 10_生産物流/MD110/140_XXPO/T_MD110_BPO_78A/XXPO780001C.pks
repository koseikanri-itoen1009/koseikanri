CREATE OR REPLACE PACKAGE xxpo780001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo780001c(spec)
 * Description      : 月次〆切処理（有償支給相殺）
 * MD.050/070       : 月次〆切処理（有償支給相殺）Issue1.0  (T_MD050_BPO_780)
 *                    計算書                                (T_MD070_BPO_78A)
 * Version          : 1.8
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
 *  2007/12/03    1.0  Masayuki Ikeda   新規作成
 *  2008/02/06    1.1  Masayuki Ikeda   ・受注明細アドオンと品目マスタを紐付ける場合、ＩＮＶ
 *                                         品目マスタを仲介する。
 *                                      ・メッセージコードを修正
 *  2008/03/10    1.2  Masayuki Ikeda   ・変更要求No.81対応
 *  2008/06/20    1.3  Yasuhisa Yamamoto ST不具合対応#135
 *  2008/07/29    1.4  Satoshi Yunba     禁則文字対応
 *  2008/12/05    1.5  Tsuyoki Yoshimoto 本番障害#446
 *  2008/12/25    1.6  Takao Ohashi      本番障害#848,850
 *  2009/03/04    1.7  Akiyoshi Shiina   本番障害#1266対応
 *  2019/09/03    1.8  N.Abe             E_本稼動_15601（生産_軽減税率対応）
 *
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_fiscal_ym          IN     VARCHAR2         --   01 : 〆切年月
     ,iv_dept_code          IN     VARCHAR2         --   02 : 請求管理部署
     ,iv_vendor_code        IN     VARCHAR2         --   03 : 取引先
-- 2019/09/03 Ver1.8 Add Start
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_out_file_type      IN     VARCHAR2         --   05 : 出力ファイル形式
     ,iv_out_rep_type       IN     VARCHAR2         --   06 : 出力帳票形式
     ,iv_browser            IN     VARCHAR2         --   07 : 閲覧者
-- 2019/09/03 Ver1.8 Add End
    ) ;
END xxpo780001c;
/
