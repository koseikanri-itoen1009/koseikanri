CREATE OR REPLACE PACKAGE BODY xxccd_oiccommon_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2023. All rights reserved.
 *
 * Package Name           : xxccd_oiccommon_pkg(body)
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
  -- ===============================
  -- グローバル定数
  -- ===============================
  cv_pkg_name CONSTANT VARCHAR2(50) := 'XXCCD_OICCOMMON_PKG';
  cv_period   CONSTANT VARCHAR2(1)  := '.';
  cv_msg_part CONSTANT VARCHAR2(3)  := ' : ';
  
 
--
  /**********************************************************************************
   * Procedure Name   : sleep
   * Description      : 待機処理
   ***********************************************************************************/
  PROCEDURE sleep(
              iv_seconds      IN  NUMBER                    -- 待機秒数
           )
  IS
  --
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'sleep';
  --
  BEGIN
    --
    DBMS_SESSION.SLEEP(iv_seconds);
    --
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
  END sleep;
--

 -- Ver1.1 Add Start
  /**********************************************************************************
   * Procedure Name   : select_jobstatus_cnt_hier
   * Description      : ジョブステータス件数取得処理（階層構造）
   ***********************************************************************************/
  PROCEDURE select_jobstatus_cnt_hier (
              iv_parent_id    IN NUMBER    -- 親プロセスID
              ,ov_error_cnt   OUT NUMBER   -- エラー件数
              ,ov_status_cnt  OUT NUMBER   -- 処理中件数
              ,ov_return_code OUT VARCHAR2 -- リターンコード
            )
  IS
    -- ===============================
    -- ローカル定数
    -- =============================== 
    cv_prg_name         CONSTANT VARCHAR2(100) := 'select_jobstatus_hier';  
    
    cv_STS_ERROR        CONSTANT VARCHAR(20) := 'ERROR';
    cv_STS_PROCES1      CONSTANT VARCHAR(20) := 'WAIT';
    cv_STS_PROCES2      CONSTANT VARCHAR(20) := 'BLOCKED';
    cv_STS_PROCES3      CONSTANT VARCHAR(20) := 'RUNNING';
    cv_STS_PROCES4      CONSTANT VARCHAR(20) := 'PAUSED';
    cv_STS_PROCES5      CONSTANT VARCHAR(20) := 'COMPLETED';
    cv_STS_PROCES6      CONSTANT VARCHAR(20) := 'READY';
    
    cv_SUCCESS          CONSTANT VARCHAR2(1) := '0';
    cv_ERROR            CONSTANT VARCHAR2(1) := '2';

    -- ===============================
    -- ローカル変数
    -- =============================== 
    nv_err_cnt     NUMBER      := 0;
    nv_proc_cnt    NUMBER      := 0;
    cv_return_code VARCHAR2(1) := cv_ERROR;
    
  BEGIN
    
    FOR vStatus IN(
      SELECT
        A.PARENT_ID
      , A.PROCESS_ID
      , A.JOB_NAME
      , A.STATUS
      FROM
        (
          SELECT
            CASE A.PARENT_ID
              WHEN A.PROCESS_ID THEN 0
              ELSE A.PARENT_ID
            END AS PARENT_ID
          , A.PROCESS_ID
          , A.JOB_NAME
          , A.DOCUMENT_ID
          , A.STATUS
 -- Ver1.2 Add Start
          , A.INSTANCE_NAME
 -- Ver1.2 Add End
          FROM
            XXCCD_JOB_REQUESTS A
        )A
 -- Ver1.2 Add Start
        WHERE NOT EXISTS(SELECT * FROM XXCCD_PROFILE_OPTION_VALUES xpov1
                          , XXCCD_PROFILE_OPTION_VALUES xpov2
                          WHERE
                              xpov1.PROFILE_OPTION_ID = 1001
                          AND xpov2.PROFILE_OPTION_ID = 1002
                          AND xpov1.LEVEL_NAME = '10001'
                          AND xpov2.LEVEL_NAME = '10001'
                          AND xpov1.LEVEL_VALUE = xpov2.LEVEL_VALUE 
                          AND A.INSTANCE_NAME = xpov1.PROFILE_OPTION_VALUE
                          AND A.JOB_NAME = xpov2.PROFILE_OPTION_VALUE )
 -- Ver1.2 Add End
      START WITH
        A.PROCESS_ID = iv_parent_id
      CONNECT BY
        PRIOR A.PROCESS_ID = A.PARENT_ID
    ) LOOP

        CASE 
          WHEN vStatus.STATUS = cv_STS_ERROR THEN 
            nv_err_cnt := nv_err_cnt + 1;
          WHEN vStatus.STATUS IN( cv_STS_PROCES1
                                  ,cv_STS_PROCES2
                                  ,cv_STS_PROCES3
                                  ,cv_STS_PROCES4
                                  ,cv_STS_PROCES5
                                  ,cv_STS_PROCES6)  THEN 
            nv_proc_cnt := nv_proc_cnt + 1;
          ELSE
            NULL;
        END CASE;
    
    END LOOP;
        
  cv_return_code := cv_SUCCESS;    
  
  ov_return_code := cv_return_code;
  ov_status_cnt  := nv_proc_cnt;
  ov_error_cnt   := nv_err_cnt;

  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      ov_return_code := cv_return_code;
      
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_period||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################

  END select_jobstatus_cnt_hier ;
 -- Ver1.1 Add End

END xxccd_oiccommon_pkg;
/
