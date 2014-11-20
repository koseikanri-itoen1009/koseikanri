CREATE OR REPLACE PACKAGE APPS.XXCOS014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A09C (spec)
 * Description      : 百貨店送り状データ作成 
 * MD.050           : 百貨店送り状データ作成 MD050_COS_014_A09
 * Version          : 1.5
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
 *  2009/02/18    1.0   H.Noda           新規作成
 *  2009/03/18    1.1   Y.Tsubomatsu     [障害COS_156] パラメータの桁拡張(帳票コード,帳票様式)
 *  2009/03/19    1.2   Y.Tsubomatsu     [障害COS_158] パラメータの編集(百貨店コード,百貨店店舗コード,枝番)
 *  2009/04/17    1.3   T.Kitajima       [T1_0375] エラーメッセージ受注番号修正(伝票番号→受注No)
 *  2009/09/07    1.4   N.Maeda          [0000403] 枝番の任意化に伴い枝番毎のループ処理追加
 *  2009/11/05    1.5   N.Maeda          [E_T4_00123]社コードセット内容修正
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_name                 IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code                IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code               IN     VARCHAR2,  --  3.帳票コード
    in_user_id                   IN     NUMBER,    --  4.ユーザID
    iv_dept_code                 IN     VARCHAR2,  --  5.百貨店コード
    iv_dept_name                 IN     VARCHAR2,  --  6.百貨店名
    iv_dept_store_code           IN     VARCHAR2,  --  7.百貨店店舗コード
    iv_edaban                    IN     VARCHAR2,  --  8.枝番
    iv_base_code                 IN     VARCHAR2,  --  9.拠点コード
    iv_base_name                 IN     VARCHAR2,  -- 10.拠点名
    iv_data_type_code            IN     VARCHAR2,  -- 11.帳票種別コード
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 12.業務系列コード
    iv_report_name               IN     VARCHAR2,  -- 13.帳票様式
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 14.店舗納品日(FROM）
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 15.店舗納品日（TO）
    iv_publish_div               IN     VARCHAR2,  -- 16.納品書発行区分
    in_publish_flag_seq          IN     NUMBER     -- 17.納品書発行フラグ順番
  );
END XXCOS014A09C;
/
