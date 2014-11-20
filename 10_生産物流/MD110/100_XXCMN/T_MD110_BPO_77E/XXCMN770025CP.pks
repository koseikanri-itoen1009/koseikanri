create or replace PACKAGE xxcmn770025cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770025CP(spec)
 * Description      : 仕入実績表作成(プロト)
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77E)
 * Version          : 1.16
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
 *  2008/04/14    1.0   T.Endou          新規作成
 *  2008/05/16    1.1   T.Ikehara        不具合ID:77E-17対応  処理年月パラYYYYM入力対応
 *  2008/05/30    1.2   T.Endou          実際単価取得方法の変更
 *  2008/06/24    1.3   I.Higa           データが無い項目でも０を出力する
 *  2008/06/25    1.4   T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/22    1.5   T.Endou          改ページ時、ヘッダが出ないパターン対応
 *  2008/10/14    1.6   A.Shiina         T_S_524対応
 *  2008/10/28    1.7   H.Itou           T_S_524対応(再対応)
 *  2008/11/13    1.8   A.Shiina         移行データ検証不具合対応
 *  2008/11/19    1.9   N.Yoshida        移行データ検証不具合対応
 *  2008/11/28    1.10  N.Yoshida        本番#182対応
 *  2008/12/04    1.11  N.Yoshida        本番#389対応
 *  2008/12/05    1.12  A.Shiina         本番#500対応
 *  2008/12/05    1.13  A.Shiina         本番#473対応
 *  2008/12/12    1.14  A.Shiina         本番#425対応
 *  2009/01/09    1.15  N.Yoshida        本番#986対応
 *  2009/07/09    1.16  Marushita        本番#1574対応
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
      errbuf                OUT   VARCHAR2,  -- エラーメッセージ
      retcode               OUT   VARCHAR2,  -- エラーコード
      iv_proc_from          IN    VARCHAR2, -- 01 : 処理年月(FROM)
      iv_proc_to            IN    VARCHAR2, -- 02 : 処理年月(TO)
      iv_prod_div           IN    VARCHAR2, -- 03 : 商品区分
      iv_item_div           IN    VARCHAR2, -- 04 : 品目区分
      iv_result_post        IN    VARCHAR2, -- 05 : 成績部署
      iv_party_code         IN    VARCHAR2, -- 06 : 仕入先
      iv_crowd_type         IN    VARCHAR2, -- 07 : 群種別
      iv_crowd_code         IN    VARCHAR2, -- 08 : 群コード
      iv_acnt_crowd_code    IN    VARCHAR2  -- 09 : 経理群コード
    );
--
END xxcmn770025cp;
/
