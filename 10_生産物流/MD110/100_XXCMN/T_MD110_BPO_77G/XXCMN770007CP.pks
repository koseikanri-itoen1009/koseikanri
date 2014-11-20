CREATE OR REPLACE PACKAGE xxcmn770007cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770007cp(spec)
 * Description      : 生産原価差異表(プロト)
 * MD.050           : 有償支給帳票Issue1.0(T_MD050_BPO_770)
 * MD.070           : 有償支給帳票Issue1.0(T_MD070_BPO_77G)
 * Version          : 1.17
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
 *  2008/04/09    1.0   K.Kamiyoshi      新規作成
 *  2008/05/16    1.1   Y.Majikina       パラメータ：処理年月がYYYYMで入力された時、エラー
 *                                       となる点を修正。
 *                                       担当部署、担当者名の最大長処理を修正。
 *  2008/05/30    1.2   T.Ikehara        原価取得方法修正
 *  2008/06/03    1.3   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/12    1.4   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除
 *  2008/06/24    1.5   T.Ikehara        数量、金額が0の場合に出力されるように修正
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/29    1.7   A.Shiina         T_TE080_BPO_770 指摘20対応
 *  2008/10/08    1.8   A.Shiina         T_S_524対応
 *  2008/10/08    1.9   A.Shiina         T_S_455対応
 *  2008/10/09    1.10  A.Shiina         T_S_422対応
 *  2008/11/11    1.11  N.Yoshida        I_S_511対応、移行データ検証不具合対応
 *  2008/11/19    1.12  N.Yoshida        移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#212対応
 *  2008/12/04    1.14  T.Mitaya         本番#379対応
 *  2009/01/16    1.15  N.Yoshida        本番#1031対応
 *  2009/06/22    1.16  Marushita        本番#1541対応
 *  2009/06/29    1.17  Marushita        本番#1554対応
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
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  -- 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月TO
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
-- 2008/10/08 v1.9 DELETE START
--     ,iv_rcv_pay_div     IN    VARCHAR2  -- 受払区分
-- 2008/10/08 v1.9 DELETE END
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
    );
--
END xxcmn770007cp;
/
