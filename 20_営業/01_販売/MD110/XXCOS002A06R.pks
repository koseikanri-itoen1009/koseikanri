CREATE OR REPLACE PACKAGE APPS.XXCOS002A06R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A06R(spec)
 * Description      : 自販機販売報告書
 * MD.050           : 自販機販売報告書 <MD050_COS_002_A06>
 * Version          : 1.3
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
 * 2012/02/16    1.0   K.Kiriu          main新規作成
 * 2013/11/12    1.2   T.Ishiwata       E_本稼働_11134対応
 *                                        入力パラメータに「納品日FROM」と「納品日TO」を追加する
 * 2018/07/06    1.3   K.Nara           E_本稼働_15005対応
 *                                        事務センター案件（支払案内書、販売報告書一括出力）
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf              OUT VARCHAR2  --    エラーメッセージ #固定#
    ,retcode             OUT VARCHAR2  --    エラーコード     #固定#
    ,iv_manager_flag     IN  VARCHAR2  --  1.管理者フラグ(Y:管理者 N:拠点)
    ,iv_execute_type     IN  VARCHAR2  --  2.実行区分(1:顧客指定 2:仕入先指定)
    ,iv_target_date      IN  VARCHAR2  --  3.対象年月
-- 2013/11/12 Ver.1.2 T.Ishiwata E_本稼動_11134 ADD START
    ,iv_dlv_date_from    IN  VARCHAR2  --    納品日FROM
    ,iv_dlv_date_to      IN  VARCHAR2  --    納品日TO
-- 2013/11/12 Ver.1.2 T.Ishiwata E_本稼動_11134 ADD END
   ,iv_sales_base_code  IN  VARCHAR2  --  4.売上拠点コード(顧客指定時のみ)
    ,iv_customer_code_01 IN  VARCHAR2  --  5.顧客コード1(顧客指定時のみ)
    ,iv_customer_code_02 IN  VARCHAR2  --  6.顧客コード2(顧客指定時のみ)
    ,iv_customer_code_03 IN  VARCHAR2  --  7.顧客コード3(顧客指定時のみ)
    ,iv_customer_code_04 IN  VARCHAR2  --  8.顧客コード4(顧客指定時のみ)
    ,iv_customer_code_05 IN  VARCHAR2  --  9.顧客コード5(顧客指定時のみ)
    ,iv_customer_code_06 IN  VARCHAR2  -- 10.顧客コード6(顧客指定時のみ)
    ,iv_customer_code_07 IN  VARCHAR2  -- 11.顧客コード7(顧客指定時のみ)
    ,iv_customer_code_08 IN  VARCHAR2  -- 12.顧客コード8(顧客指定時のみ)
    ,iv_customer_code_09 IN  VARCHAR2  -- 13.顧客コード9(顧客指定時のみ)
    ,iv_customer_code_10 IN  VARCHAR2  -- 14.顧客コード10(顧客指定時のみ)
    ,iv_vendor_code_01   IN  VARCHAR2  -- 15.仕入先コード1(仕入先指定時のみ)
    ,iv_vendor_code_02   IN  VARCHAR2  -- 16.仕入先コード2(仕入先指定時のみ)
    ,iv_vendor_code_03   IN  VARCHAR2  -- 17.仕入先コード3(仕入先指定時のみ)
-- Ver.1.3 [障害E_本稼動_15005] SCSK K.Nara ADD START
    ,in_request_id       IN  NUMBER    -- 18.要求ID(アップロード時のみ)
    ,in_output_num       IN  NUMBER    -- 19.出力番号(アップロード時のみ)
-- Ver.1.3 [障害E_本稼動_15005] SCSK K.Nara ADD END
  );
END XXCOS002A06R;
/
