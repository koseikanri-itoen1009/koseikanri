CREATE OR REPLACE PACKAGE XXCOS_TASK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_TASK_PKG(spec)
 * Description      : 共通関数パッケージ(販売)
 * MD.070           : 共通関数    MD070_IPO_COS
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  task_entry                  P                 訪問・有効実績登録
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/12/12    1.0   T.kitajima       新規作成
 *  2009/02/18    1.1   T.kitajima       [COS_091]消化VD対応
 *  2009/05/18    1.2   T.kitajima       [T1_0652]入金情報時の登録元ソース番号必須解除
 *  2009/11/24    1.3   S.Miyakoshi      TASKデータ取得時の日付の条件変更
 *
 ****************************************************************************************/
--
  /************************************************************************
   * Procedure Name  : task_entry
   * Description     : 訪問・有効実績登録
   ************************************************************************/
  PROCEDURE task_entry(
               ov_errbuf          OUT NOCOPY  VARCHAR2                --エラーメッセージ
              ,ov_retcode         OUT NOCOPY  VARCHAR2                --リターンコード
              ,ov_errmsg          OUT NOCOPY  VARCHAR2                --ユーザー・エラー・メッセージ
              ,in_resource_id     IN          NUMBER    DEFAULT NULL  --リソースID
              ,in_party_id        IN          NUMBER    DEFAULT NULL  --パーティID
              ,iv_party_name      IN          VARCHAR2  DEFAULT NULL  --パーティ名称
              ,id_visit_date      IN          DATE      DEFAULT NULL  --訪問日時
              ,iv_description     IN          VARCHAR2  DEFAULT NULL  --詳細内容
              ,in_sales_amount    IN          NUMBER    DEFAULT NULL  --売上金額(2008/12/12 追加)
              ,iv_input_division  IN          VARCHAR2  DEFAULT NULL  --入力区分(2008/12/17 追加)
              ,iv_entry_class     IN          VARCHAR2  DEFAULT NULL  --ＤＦＦ１２（登録区分）
              ,iv_source_no       IN          VARCHAR2  DEFAULT NULL  --ＤＦＦ１３（登録元ソース番号）
              ,iv_customer_status IN          VARCHAR2  DEFAULT NULL  --ＤＦＦ１４（顧客ステータス）
              );
  --
END XXCOS_TASK_PKG;
/
