CREATE OR REPLACE PACKAGE xxcmn770016cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770016cp(spec)
 * Description      : 出庫実績表(入力パターン)(プロト)
 * MD.050/070       : 月次〆処理(経理)Issue1.0 (T_MD050_BPO_770)
 *                    月次〆処理(経理)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.2
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  main                      PROCEDURE : コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/17    1.0   Y.Itou           新規作成
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
  -- プログラム名（コンカレント・テンプレート）
  gc_rtf_name_01     CONSTANT  VARCHAR2(20) := 'XXCMN770061'; -- 集計:成績部署,品目区分,倉庫,出荷先
  gc_rtf_name_02     CONSTANT  VARCHAR2(20) := 'XXCMN770062'; -- 集計:成績部署,品目区分,倉庫
  gc_rtf_name_03     CONSTANT  VARCHAR2(20) := 'XXCMN770063'; -- 集計:成績部署,品目区分,出荷先
  gc_rtf_name_04     CONSTANT  VARCHAR2(20) := 'XXCMN770064'; -- 集計:成績部署,品目区分
  gc_rtf_name_05     CONSTANT  VARCHAR2(20) := 'XXCMN770065'; -- 集計:品目区分,倉庫,出荷先
  gc_rtf_name_06     CONSTANT  VARCHAR2(20) := 'XXCMN770066'; -- 集計:品目区分,倉庫
  gc_rtf_name_07     CONSTANT  VARCHAR2(20) := 'XXCMN770067'; -- 集計:品目区分,出荷先
  gc_rtf_name_08     CONSTANT  VARCHAR2(20) := 'XXCMN770068'; -- 集計:品目区分
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
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
    ) ;
END xxcmn770016cp;
/
