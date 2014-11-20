CREATE OR REPLACE PACKAGE xxcmn770026cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770026cp(spec)
 * Description      : 出庫実績表(プロト)
 * MD.050/070       : 月次〆処理(経理)Issue1.0 (T_MD050_BPO_770)
 *                    月次〆処理(経理)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.26
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
 *  2008/04/11    1.0   Y.Itou           新規作成
 *  2008/05/16    1.1   T.Endou          不具合ID:77F-09,10対応
 *                                       77F-09 処理年月パラYYYYM入力対応
 *                                       77F-10 担当部署、担当者名の最大文字数制限の修正
 *  2008/05/16    1.2   T.Endou          実際原価取得方法の変更
 *  2008/06/16    1.3   T.Endou          取引区分
 *                                        ・有償
 *                                        ・振替有償_出荷
 *                                        ・商品振替有償_出荷
 *                                       場合は、受注ヘッダアドオン.取引先サイトIDで紐付ける
 *  2008/06/24    1.4   I.Higa           データが無い項目でも０を出力する
 *  2008/06/25    1.5   T.Endou          特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/18    1.6   T.Ikehara        出力件数カウントタグ追加
 *  2008/08/07    1.7   T.Endou          参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma26_v」
 *  2008/09/02    1.8   A.Shiina         仕様不備障害#T_S_475対応
 *  2008/09/22    1.9   A.Shiina         内部変更要求#236対応
 *  2008/10/15    1.10  A.Shiina         T_S_524対応
 *  2008/10/24    1.12  T.Yoshida        T_S_524対応(再対応2)
 *                                           変更箇所多数のため、修正履歴を残していないので、
 *                                           修正箇所確認の際は前Verと差分比較すること
 *  2008/11/12    1.13  N.Yoshida        移行データ検証不具合対応(履歴削除)
 *  2008/12/02    1.14  A.Shiina         本番#207対応
 *  2008/12/08    1.15  N.Yoshida        本番障害数値あわせ対応(受注ヘッダの最新フラグを追加)
 *  2008/12/13    1.16  A.Shiina         本番#428対応
 *  2008/12/13    1.17  N.Yoshida        本番#428対応(再対応)
 *  2008/12/16    1.18  A.Shiina         本番#749対応
 *  2008/12/16    1.19  A.Shiina         本番#754対応 -- 対応削除
 *  2008/12/17    1.20  A.Shiina         本番#428対応(PT対応)
 *  2008/12/18    1.21  A.Shiina         本番#799対応
 *  2009/01/09    1.22  A.Shiina         本番#987対応
 *  2009/01/10    1.23  A.Shiina         本番#987対応(再対応)
 *  2009/01/21    1.24  N.Yoshida        本番#1016対応
 *  2009/05/29    1.25  Marushita        本番障害1511対応
 *  2009/10/02    1.26  Marushita        本番障害1648対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
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
     ,iv_proc_from       IN    VARCHAR2  --   01 : 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : 処理年月TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : 受払区分
     ,iv_prod_div        IN    VARCHAR2  --   04 : 商品区分
     ,iv_item_div        IN    VARCHAR2  --   05 : 品目区分
     ,iv_result_post     IN    VARCHAR2  --   06 : 成績部署
     ,iv_whse_code       IN    VARCHAR2  --   07 : 倉庫コード
     ,iv_party_code      IN    VARCHAR2  --   08 : 出荷先コード
     ,iv_crowd_type      IN    VARCHAR2  --   09 : 郡種別
     ,iv_crowd_code      IN    VARCHAR2  --   10 : 郡コード
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : 経理群コード
     ,iv_output_type     IN    VARCHAR2  --   12 : 出力種別
    );
--
END xxcmn770026cp;
/
