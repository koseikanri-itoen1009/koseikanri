CREATE OR REPLACE PACKAGE xxpo310002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo310002c(spec)
 * Description      : HHT発注情報IF
 * MD.050           : 受入実績            T_MD050_BPO_310
 * MD.070           : HHT発注情報IF       T_MD070_BPO_31E
 * Version          : 1.7
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
 *  2008/04/08    1.0   Oracle 山根 一浩 初回作成
 *  2008/04/21    1.1   Oracle 山根 一浩 変更要求No43対応
 *  2008/05/23    1.2   Oracle 藤井 良平 結合テスト不具合（シナリオ4-1）
 *  2008/07/14    1.3   Oracle 椎名 昭圭 仕様不備障害#I_S_001.4,#I_S_192.1.2,#T_S_435対応
 *  2008/09/01    1.4   Oracle 山根 一浩 T_TE080_BPO_310 指摘9対応
 *  2008/09/17    1.5   Oracle 大橋 孝郎 指摘204対応
 *  2009/01/26    1.6   Oracle 椎名 昭圭 本番#1046対応
 *  2010/01/19    1.7   SCS    吉元 強樹 E_本稼動#1075対応
 *****************************************************************************************/
--
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_from_date  IN            VARCHAR2,         -- 1.納入日(FROM)
    iv_to_date    IN            VARCHAR2,         -- 2.納入日(TO)
-- 2008/07/14 1.3 UPDATE Start
--    iv_inv_code   IN            VARCHAR2,         -- 3.納入先コード
--    iv_vendor_id  IN            VARCHAR2)         -- 4.取引先コード
    iv_inv_code_01 IN           VARCHAR2,         -- 03.納入先コード01
    iv_inv_code_02 IN           VARCHAR2,         -- 04.納入先コード02
    iv_inv_code_03 IN           VARCHAR2,         -- 05.納入先コード03
    iv_inv_code_04 IN           VARCHAR2,         -- 06.納入先コード04
    iv_inv_code_05 IN           VARCHAR2,         -- 07.納入先コード05
    iv_inv_code_06 IN           VARCHAR2,         -- 08.納入先コード06
    iv_inv_code_07 IN           VARCHAR2,         -- 09.納入先コード07
    iv_inv_code_08 IN           VARCHAR2,         -- 10.納入先コード08
    iv_inv_code_09 IN           VARCHAR2,         -- 11.納入先コード09
    iv_inv_code_10 IN           VARCHAR2,         -- 12.納入先コード10
    iv_vendor_id   IN           VARCHAR2);        -- 13.取引先コード
-- 2008/07/14 1.3 UPDATE End
END xxpo310002c;
/
