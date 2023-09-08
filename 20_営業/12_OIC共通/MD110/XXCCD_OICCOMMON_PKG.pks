CREATE OR REPLACE PACKAGE xxccd_oiccommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2023. All rights reserved.
 *
 * Package Name           : xxccd_oiccommon_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCD_共通関数
 * Version                : 1.1
 *
 * Program List
 *  --------------------      ---- -----   --------------------------------------------------
 *   Name                     Type  Ret     Description
 *  --------------------      ---- -----   --------------------------------------------------
 *  sleep                     P            待機処理
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2023-04-17    1.0  SCSK久保田      新規作成
 *  2023-07-26    1.1  SCSK細沼        E_本稼動_19362対応
 *  2023-08-03    1.2  SCSK細沼        E_本稼動_19405対応
 *****************************************************************************************/
--

  -- 待機処理
  PROCEDURE sleep(
              iv_seconds      IN  NUMBER                    -- 待機秒数
           )
    ;
  --
  
 -- Ver1.1 Add Start
  -- ジョブステータス件数取得処理（階層構造）
  PROCEDURE select_jobstatus_cnt_hier (
              iv_parent_id    IN NUMBER    -- 親プロセスID
              ,ov_error_cnt   OUT NUMBER   -- エラー件数
              ,ov_status_cnt  OUT NUMBER   -- 処理中件数
              ,ov_return_code OUT VARCHAR2 -- リターンコード
            )
  ;
 -- Ver1.1 Add End
  
END xxccd_oiccommon_pkg;
/
