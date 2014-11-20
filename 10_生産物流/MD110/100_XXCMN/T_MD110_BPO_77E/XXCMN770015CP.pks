CREATE OR REPLACE PACKAGE xxcmn770015cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770015CP(spec)
 * Description      : 仕入実績表作成(プロト)
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77E)
 * Version          : 1.2
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
 *  2008/12/18    1.2   A.Shiina         子コンカレントを起動したら終了
 *
 *****************************************************************************************/
--
  -- ======================================================
  -- ユーザー宣言部
  -- ======================================================
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パラメータ．ALL
  dept_code_all       CONSTANT VARCHAR2(20) := 'ALL' ;   -- ALL指定
--
  -- プログラム名（コンカレント・テンプレート）
  program_id_01       CONSTANT VARCHAR2(20) := 'XXCMN770051' ; -- 品目区分
  program_id_02       CONSTANT VARCHAR2(20) := 'XXCMN770052' ; -- 品目区分・成績部署
  program_id_03       CONSTANT VARCHAR2(20) := 'XXCMN770053' ; -- 品目区分・仕入先
  program_id_04       CONSTANT VARCHAR2(20) := 'XXCMN770054' ; -- 品目区分・仕入先・成績部署
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_proc_from          IN     VARCHAR2         --   01 : 処理年月(FROM)
     ,iv_proc_to            IN     VARCHAR2         --   02 : 処理年月(TO)
     ,iv_prod_div           IN     VARCHAR2         --   03 : 商品区分
     ,iv_item_div           IN     VARCHAR2         --   04 : 品目区分
     ,iv_result_post        IN     VARCHAR2         --   05 : 成績部署
     ,iv_party_code         IN     VARCHAR2         --   06 : 仕入先
     ,iv_crowd_type         IN     VARCHAR2         --   07 : 群種別
     ,iv_crowd_code         IN     VARCHAR2         --   08 : 群コード
     ,iv_acnt_crowd_code    IN     VARCHAR2         --   09 : 経理群コード
    ) ;
END xxcmn770015cp;
/
