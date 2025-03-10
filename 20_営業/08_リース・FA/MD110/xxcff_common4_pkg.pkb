create or replace PACKAGE BODY XXCFF_COMMON4_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff_common4_pkg(body)
 * Description      : [X_ñÖA¤ÊÖ
 * MD.050           : Èµ
 * Version          : 1.2
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_co_hed             P           [X_ño^Ö
 *  insert_co_lin             P           [X_ñ¾×o^Ö
 *  insert_co_his             P           [X_ñðo^Ö
 *  update_co_hed             P           [X_ñXVÖ
 *  update_co_lin             P           [X_ñ¾×XVÖ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-19    1.0   SCSâEèS      VKì¬
 *  2013-06-26    1.1   SCSKìOç     [E_{Ò®_10871]ÁïÅÅÎ
 *  2016-08-10    1.2   SCSKmØdl     [E_{Ò®_13658]©Ì@ÏpNÏXÎ
 *
 *****************************************************************************************/
--
--#######################  ÅèO[oèé¾ START   #######################
--
  --Xe[^XER[h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --³í:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --x:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --Ùí:2
  --WHOJ
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  Åè END   ##################################
--
--#######################  ÅèO[oÏé¾ START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- ÎÛ
  gn_normal_cnt    NUMBER;                    -- ³í
  gn_error_cnt     NUMBER;                    -- G[
  gn_warn_cnt      NUMBER;                    -- XLbv
--
--################################  Åè END   ##################################
--
--##########################  Åè¤ÊáOé¾ START  ###########################
--
  --*** ¤ÊáO ***
--
  global_process_expt       EXCEPTION;
  --*** ¤ÊÖáO ***
  global_api_expt           EXCEPTION;
  --*** ¤ÊÖOTHERSáO ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  Åè END   ##################################
--
  --
  -- ===============================
  -- [U[è`O[oè
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'xxcff_common4_pkg'; -- pbP[W¼
  cv_app_kbn_cff     CONSTANT VARCHAR2(5)   := 'XXCFF';
  --
  -- ===============================
  -- [U[è`O[o^
  -- ===============================
--
  -- ===============================
  -- [U[è`O[oÏ
  -- ===============================
--
  /**********************************************************************************
   * Function Name    : insert_co_hed
   * Description      : [X_ño^
   ***********************************************************************************/
  PROCEDURE insert_co_hed(
    io_contract_data_rec   IN OUT NOCOPY cont_hed_data_rtype  -- _ñîñ
   ,ov_errbuf              OUT NOCOPY VARCHAR2                -- G[EbZ[W
   ,ov_retcode             OUT NOCOPY VARCHAR2                -- ^[ER[h
   ,ov_errmsg              OUT NOCOPY VARCHAR2                -- [U[EG[EbZ[W
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_hed';   -- vO¼
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- G[EbZ[W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ^[ER[h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- [U[EG[EbZ[W
    --
    -- ===============================
    -- [Je[u^
    -- ===============================
    --
    -- ===============================
    -- [Je[u^Ï
    -- ===============================
    --
    --
  BEGIN
  --
    -- ú»
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.V[PXÌæ¾
    -- ***************************************************
    --
    SELECT    xxcff_contract_headers_s1.NEXTVAL
    INTO      io_contract_data_rec.contract_header_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.[X_ño^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_headers(
       contract_header_id         -- _ñàID
     , contract_number            -- _ñÔ
     , lease_class                -- [XíÊ
     , lease_type                 -- [Xæª
     , lease_company              -- [XïÐ
     , re_lease_times             -- Ä[Xñ
     , comments                   -- ¼
     , contract_date              -- [X_ñú
     , payment_frequency          -- x¥ñ
     , payment_type               -- px
     , payment_years              -- Nx
     , lease_start_date           -- [XJnú
     , lease_end_date             -- [XI¹ú
     , first_payment_date         -- ñx¥ú
     , second_payment_date        -- QñÚx¥ú
     , third_payment_date         -- RñÚÈ~x¥ú
     , start_period_name          -- ïpvãïvïvúÔ   
     , lease_payment_flag         -- x¥væ®¹tO
     , tax_code                   -- ÅàR[h
     , created_by                 -- ì¬Ò
     , creation_date              -- ì¬ú
     , last_updated_by            -- ÅIXVÒ
     , last_update_date           -- ÅIXVú
     , last_update_login          -- ÅIXVÛ¸Þ²Ý
     , request_id                 -- vID
     , program_application_id     -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
     , program_id                 -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
     , program_update_date        -- ÌßÛ¸Þ×ÑXVú
    )
     VALUES(
       io_contract_data_rec.contract_header_id         -- _ñàID
     , io_contract_data_rec.contract_number            -- _ñÔ
     , io_contract_data_rec.lease_class                -- [XíÊ
     , io_contract_data_rec.lease_type                 -- [Xæª
     , io_contract_data_rec.lease_company              -- [XïÐ
     , io_contract_data_rec.re_lease_times             -- Ä[Xñ
     , io_contract_data_rec.comments                   -- ¼
     , io_contract_data_rec.contract_date              -- [X_ñú
     , io_contract_data_rec.payment_frequency          -- x¥ñ
     , io_contract_data_rec.payment_type               -- px
     , io_contract_data_rec.payment_years              -- Nx
     , io_contract_data_rec.lease_start_date           -- [XJnú
     , io_contract_data_rec.lease_end_date             -- [XI¹ú
     , io_contract_data_rec.first_payment_date         -- ñx¥ú
     , io_contract_data_rec.second_payment_date        -- QñÚx¥ú
     , io_contract_data_rec.third_payment_date         -- RñÚÈ~x¥ú
     , io_contract_data_rec.start_period_name          -- ïpvãïvïvúÔ   
     , io_contract_data_rec.lease_payment_flag         -- x¥væ®¹tO
     , io_contract_data_rec.tax_code                   -- ÅàR[h
     , io_contract_data_rec.created_by                 -- ì¬Ò
     , io_contract_data_rec.creation_date              -- ì¬ú
     , io_contract_data_rec.last_updated_by            -- ÅIXVÒ
     , io_contract_data_rec.last_update_date           -- ÅIXVú
     , io_contract_data_rec.last_update_login          -- ÅIXVÛ¸Þ²Ý
     , io_contract_data_rec.request_id                 -- vID
     , io_contract_data_rec.program_application_id     -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
     , io_contract_data_rec.program_id                 -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
     , io_contract_data_rec.program_update_date        -- ÌßÛ¸Þ×ÑXVú
    )
    ;
  --
--
  EXCEPTION
--###############################  ÅèáO START   ###################################
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  Åè END   #########################################
--
  END insert_co_hed;
  --
  /**********************************************************************************
   * Function Name    : insert_co_lin
   * Description      : [X_ñ¾×o^
   ***********************************************************************************/
  PROCEDURE insert_co_lin(
    io_contract_data_rec   IN OUT NOCOPY cont_lin_data_rtype  -- _ñ¾×îñ
   ,ov_errbuf              OUT NOCOPY VARCHAR2                -- G[EbZ[W
   ,ov_retcode             OUT NOCOPY VARCHAR2                -- ^[ER[h
   ,ov_errmsg              OUT NOCOPY VARCHAR2                -- [U[EG[EbZ[W
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_lin';   -- vO¼
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- G[EbZ[W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ^[ER[h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- [U[EG[EbZ[W
    --
    -- ===============================
    -- [Je[u^
    -- ===============================
    --
    -- ===============================
    -- [Je[u^Ï
    -- ===============================
    --
  BEGIN
  --
    -- ú»
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.V[PXÌæ¾
    -- ***************************************************
    --
    SELECT    xxcff_contract_lines_s1.NEXTVAL
    INTO      io_contract_data_rec.contract_line_id
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.[X_ñ¾×o^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_lines(
       contract_line_id            -- _ñà¾×ID
     , contract_header_id          -- _ñàID
     , contract_line_num           -- _ñ}Ô
     , contract_status             -- _ñXe[^X
     , first_charge                -- ñz[X¿_[X¿
     , first_tax_charge            -- ñÁïÅz_[X¿
     , first_total_charge          -- ñv[X¿
     , second_charge               -- QñÚz[X¿_[X¿
     , second_tax_charge           -- QñÚÁïÅz_[X¿
     , second_total_charge         -- QñÚv[X¿
     , first_deduction             -- ñz[X¿_Tz
     , first_tax_deduction         -- ñÁïÅz_Tz
     , first_total_deduction       -- ñvTz
     , second_deduction            -- QñÚÈ~z[X¿_Tz
     , second_tax_deduction        -- QñÚÈ~ÁïÅz_Tz
     , second_total_deduction      -- QñÚÈ~vTz
     , gross_charge                -- z[X¿_[X¿
     , gross_tax_charge            -- zÁïÅz_[X¿
     , gross_total_charge          -- zv_[X¿
     , gross_deduction             -- z[X¿_Tz
     , gross_tax_deduction         -- zÁïÅ_Tz
     , gross_total_deduction       -- zv_Tz
     , lease_kind                  -- [XíÞ
     , estimated_cash_price        -- ©Ï»àwüàz
     , present_value_discount_rate -- »à¿lø¦
     , present_value               -- »à¿l
     , life_in_months              -- @èÏpN
     , original_cost               -- æ¾¿i
     , calc_interested_rate        -- vZq¦
     , object_header_id            -- ¨àid
     , asset_category              -- YíÞ
     , expiration_date             -- ¹ú
     , cancellation_date           -- rðñú
     , vd_if_date                  -- [X_ñîñAgú
     , info_sys_if_date            -- [XÇîñAgú
     , first_installation_address  -- ñÝuê
     , first_installation_place    -- ñÝuæ
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , tax_code                    -- ÅàR[h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
-- Ver.1.2 ADD Start
     , original_cost_type1         -- [XÂz_´_ñ
     , original_cost_type2         -- [XÂz_Ä[X
-- Ver.1.2 ADD End
     , created_by                  -- ì¬Ò
     , creation_date               -- ì¬ú
     , last_updated_by             -- ÅIXVÒ
     , last_update_date            -- ÅIXVú
     , last_update_login           -- ÅIXVÛ¸Þ²Ý
     , request_id                  -- vID
     , program_application_id      -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
     , program_id                  -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
     , program_update_date         -- ÌßÛ¸Þ×ÑXVú
    )
    VALUES(
       io_contract_data_rec.contract_line_id            -- _ñà¾×ID
     , io_contract_data_rec.contract_header_id          -- _ñàID
     , io_contract_data_rec.contract_line_num           -- _ñ}Ô
     , io_contract_data_rec.contract_status             -- _ñXe[^X
     , io_contract_data_rec.first_charge                -- ñz[X¿_[X¿
     , io_contract_data_rec.first_tax_charge            -- ñÁïÅz_[X¿
     , io_contract_data_rec.first_total_charge          -- ñv[X¿
     , io_contract_data_rec.second_charge               -- QñÚz[X¿_[X¿
     , io_contract_data_rec.second_tax_charge           -- QñÚÁïÅz_[X¿
     , io_contract_data_rec.second_total_charge         -- QñÚv[X¿
     , io_contract_data_rec.first_deduction             -- ñz[X¿_Tz
     , io_contract_data_rec.first_tax_deduction         -- ñÁïÅz_Tz
     , io_contract_data_rec.first_total_deduction       -- ñvTz
     , io_contract_data_rec.second_deduction            -- QñÚÈ~z[X¿_Tz
     , io_contract_data_rec.second_tax_deduction        -- QñÚÈ~ÁïÅz_Tz
     , io_contract_data_rec.second_total_deduction      -- QñÚÈ~vTz
     , io_contract_data_rec.gross_charge                -- z[X¿_[X¿
     , io_contract_data_rec.gross_tax_charge            -- zÁïÅz_[X¿
     , io_contract_data_rec.gross_total_charge          -- zv_[X¿
     , io_contract_data_rec.gross_deduction             -- z[X¿_Tz
     , io_contract_data_rec.gross_tax_deduction         -- zÁïÅ_Tz
     , io_contract_data_rec.gross_total_deduction       -- zv_Tz
     , io_contract_data_rec.lease_kind                  -- [XíÞ
     , io_contract_data_rec.estimated_cash_price        -- ©Ï»àwüàz
     , io_contract_data_rec.present_value_discount_rate -- »à¿lø¦
     , io_contract_data_rec.present_value               -- »à¿l
     , io_contract_data_rec.life_in_months              -- @èÏpN
     , io_contract_data_rec.original_cost               -- æ¾¿i
     , io_contract_data_rec.calc_interested_rate        -- vZq¦
     , io_contract_data_rec.object_header_id            -- ¨àid
     , io_contract_data_rec.asset_category              -- YíÞ
     , io_contract_data_rec.expiration_date             -- ¹ú
     , io_contract_data_rec.cancellation_date           -- rðñú
     , io_contract_data_rec.vd_if_date                  -- [X_ñîñAgú
     , io_contract_data_rec.info_sys_if_date            -- [XÇîñAgú
     , io_contract_data_rec.first_installation_address  -- ñÝuê
     , io_contract_data_rec.first_installation_place    -- ñÝuæ
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , io_contract_data_rec.tax_code                    -- ÅàR[h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
-- Ver.1.2 ADD Start
     , io_contract_data_rec.original_cost_type1         -- [XÂz_´_ñ
     , io_contract_data_rec.original_cost_type2         -- [XÂz_Ä[X
-- Ver.1.2 ADD End
     , io_contract_data_rec.created_by                  -- ì¬Ò
     , io_contract_data_rec.creation_date               -- ì¬ú
     , io_contract_data_rec.last_updated_by             -- ÅIXVÒ
     , io_contract_data_rec.last_update_date            -- ÅIXVú
     , io_contract_data_rec.last_update_login           -- ÅIXVÛ¸Þ²Ý
     , io_contract_data_rec.request_id                  -- vID
     , io_contract_data_rec.program_application_id      -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
     , io_contract_data_rec.program_id                  -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
     , io_contract_data_rec.program_update_date         -- ÌßÛ¸Þ×ÑXVú
    )
    ;
    --
--
  EXCEPTION
--###############################  ÅèáO START   ###################################
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  Åè END   #########################################
--
  END insert_co_lin;
  --
  /**********************************************************************************
   * Function Name    : insert_co_his
   * Description      : [X_ñðo^
   ***********************************************************************************/
  PROCEDURE insert_co_his(
    io_contract_lin_data_rec IN OUT NOCOPY cont_lin_data_rtype  -- _ñ¾×îñ
   ,io_contract_his_data_rec IN OUT NOCOPY cont_his_data_rtype  -- _ñðîñ
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'insert_co_his';   -- vO¼
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- G[EbZ[W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ^[ER[h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- [U[EG[EbZ[W
    --
    ln_history_num  xxcff_contract_histories.history_num%TYPE; --ÏXð
    --
    -- ===============================
    -- [Je[u^
    -- ===============================
    --
    -- ===============================
    -- [Je[u^Ï
    -- ===============================
    --
  BEGIN
  --
    -- ú»
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.V[PXÌæ¾
    -- ***************************************************
    --
    SELECT    xxcff_contract_histories_s1.NEXTVAL
    INTO      ln_history_num
    FROM      dual
    ;
    --
    -- ***************************************************
    -- 2.[X_ñðo^
    -- ***************************************************
    --
    INSERT INTO xxcff_contract_histories(
       contract_header_id          -- _ñàID
     , contract_line_id            -- _ñà¾×ID
     , history_num                 -- ÏXð
     , contract_status             -- _ñXe[^X
     , first_charge                -- ñz[X¿_[X¿
     , first_tax_charge            -- ñÁïÅz_[X¿
     , first_total_charge          -- ñv[X¿
     , second_charge               -- QñÚz[X¿_[X¿
     , second_tax_charge           -- QñÚÁïÅz_[X¿
     , second_total_charge         -- QñÚv[X¿
     , first_deduction             -- ñz[X¿_Tz
     , first_tax_deduction         -- ñÁïÅz_Tz
     , first_total_deduction       -- ñvTz
     , second_deduction            -- QñÚÈ~z[X¿_Tz
     , second_tax_deduction        -- QñÚÈ~ÁïÅz_Tz
     , second_total_deduction      -- QñÚÈ~vTz
     , gross_charge                -- z[X¿_[X¿
     , gross_tax_charge            -- zÁïÅz_[X¿
     , gross_total_charge          -- zv_[X¿
     , gross_deduction             -- z[X¿_Tz
     , gross_tax_deduction         -- zÁïÅ_Tz
     , gross_total_deduction       -- zv_Tz
     , lease_kind                  -- [XíÞ
     , estimated_cash_price        -- ©Ï»àwüàz
     , present_value_discount_rate -- »à¿lø¦
     , present_value               -- »à¿l
     , life_in_months              -- @èÏpN
     , original_cost               -- æ¾¿i
     , calc_interested_rate        -- vZq¦
     , object_header_id            -- ¨àid
     , asset_category              -- YíÞ
     , expiration_date             -- ¹ú
     , cancellation_date           -- rðñú
     , vd_if_date                  -- [X_ñîñAgú
     , info_sys_if_date            -- [XÇîñAgú
     , first_installation_address  -- ñÝuê
     , first_installation_place    -- ñÝuæ
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , tax_code                    -- ÅàR[h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , accounting_date             -- vãú
     , accounting_if_flag          -- ïvIFtO
     , description                 -- Ev
     , created_by                  -- ì¬Ò
     , creation_date               -- ì¬ú
     , last_updated_by             -- ÅIXVÒ
     , last_update_date            -- ÅIXVú
     , last_update_login           -- ÅIXVÛ¸Þ²Ý
     , request_id                  -- vID
     , program_application_id      -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
     , program_id                  -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
     , program_update_date         -- ÌßÛ¸Þ×ÑXVú
     )
    VALUES(
       io_contract_lin_data_rec.contract_header_id          -- _ñàID
     , io_contract_lin_data_rec.contract_line_id            -- _ñà¾×ID
     , ln_history_num                                       -- ÏXð
     , io_contract_lin_data_rec.contract_status             -- _ñXe[^X
     , io_contract_lin_data_rec.first_charge                -- ñz[X¿_[X¿
     , io_contract_lin_data_rec.first_tax_charge            -- ñÁïÅz_[X¿
     , io_contract_lin_data_rec.first_total_charge          -- ñv[X¿
     , io_contract_lin_data_rec.second_charge               -- QñÚz[X¿_[X¿
     , io_contract_lin_data_rec.second_tax_charge           -- QñÚÁïÅz_[X¿
     , io_contract_lin_data_rec.second_total_charge         -- QñÚv[X¿
     , io_contract_lin_data_rec.first_deduction             -- ñz[X¿_Tz
     , io_contract_lin_data_rec.first_tax_deduction         -- ñÁïÅz_Tz
     , io_contract_lin_data_rec.first_total_deduction       -- ñvTz
     , io_contract_lin_data_rec.second_deduction            -- QñÚÈ~z[X¿_Tz
     , io_contract_lin_data_rec.second_tax_deduction        -- QñÚÈ~ÁïÅz_Tz
     , io_contract_lin_data_rec.second_total_deduction      -- QñÚÈ~vTz
     , io_contract_lin_data_rec.gross_charge                -- z[X¿_[X¿
     , io_contract_lin_data_rec.gross_tax_charge            -- zÁïÅz_[X¿
     , io_contract_lin_data_rec.gross_total_charge          -- zv_[X¿
     , io_contract_lin_data_rec.gross_deduction             -- z[X¿_Tz
     , io_contract_lin_data_rec.gross_tax_deduction         -- zÁïÅ_Tz
     , io_contract_lin_data_rec.gross_total_deduction       -- zv_Tz
     , io_contract_lin_data_rec.lease_kind                  -- [XíÞ
     , io_contract_lin_data_rec.estimated_cash_price        -- ©Ï»àwüàz
     , io_contract_lin_data_rec.present_value_discount_rate -- »à¿lø¦
     , io_contract_lin_data_rec.present_value               -- »à¿l
     , io_contract_lin_data_rec.life_in_months              -- @èÏpN
     , io_contract_lin_data_rec.original_cost               -- æ¾¿i
     , io_contract_lin_data_rec.calc_interested_rate        -- vZq¦
     , io_contract_lin_data_rec.object_header_id            -- ¨àid
     , io_contract_lin_data_rec.asset_category              -- YíÞ
     , io_contract_lin_data_rec.expiration_date             -- ¹ú
     , io_contract_lin_data_rec.cancellation_date           -- rðñú
     , io_contract_lin_data_rec.vd_if_date                  -- [X_ñîñAgú
     , io_contract_lin_data_rec.info_sys_if_date            -- [XÇîñAgú
     , io_contract_lin_data_rec.first_installation_address  -- ñÝuê
     , io_contract_lin_data_rec.first_installation_place    -- ñÝuæ
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
     , io_contract_lin_data_rec.tax_code                    -- ÅàR[h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
     , io_contract_his_data_rec.accounting_date             -- vãú
     , io_contract_his_data_rec.accounting_if_flag          -- ïvIFtO
     , io_contract_his_data_rec.description                 -- Ev
     , io_contract_lin_data_rec.created_by                  -- ì¬Ò
     , io_contract_lin_data_rec.creation_date               -- ì¬ú
     , io_contract_lin_data_rec.last_updated_by             -- ÅIXVÒ
     , io_contract_lin_data_rec.last_update_date            -- ÅIXVú
     , io_contract_lin_data_rec.last_update_login           -- ÅIXVÛ¸Þ²Ý
     , io_contract_lin_data_rec.request_id                  -- vID
     , io_contract_lin_data_rec.program_application_id      -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
     , io_contract_lin_data_rec.program_id                  -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
     , io_contract_lin_data_rec.program_update_date         -- ÌßÛ¸Þ×ÑXVú
    )
    ;
  --
--
  EXCEPTION
--###############################  ÅèáO START   ###################################
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  Åè END   #########################################
--
  END insert_co_his;
  --
  /**********************************************************************************
   * Function Name    : update_co_hed
   * Description      : [X_ñXV
   ***********************************************************************************/
  PROCEDURE update_co_hed(
    io_contract_data_rec IN OUT NOCOPY cont_hed_data_rtype    -- _ñîñ
   ,ov_errbuf               OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode              OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg               OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_co_hed';   -- vO¼
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- G[EbZ[W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ^[ER[h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- [U[EG[EbZ[W
    --
    -- ===============================
    -- [Je[u^
    -- ===============================
    --
    -- ===============================
    -- [Je[u^Ï
    -- ===============================
    --
  BEGIN
  --
    -- ú»
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    --
    -- ***************************************************
    -- 1.[X_ñXV
    -- ***************************************************
    --
    UPDATE xxcff_contract_headers  xch  -- [X_ñe[u
    SET    xch.contract_number         = io_contract_data_rec.contract_number            -- _ñÔ
         , xch.lease_class             = io_contract_data_rec.lease_class                -- [XíÊ
         , xch.lease_type              = io_contract_data_rec.lease_type                 -- [Xæª
         , xch.lease_company           = io_contract_data_rec.lease_company              -- [XïÐ
         , xch.re_lease_times          = io_contract_data_rec.re_lease_times             -- Ä[Xñ
         , xch.comments                = io_contract_data_rec.comments                   -- ¼
         , xch.contract_date           = io_contract_data_rec.contract_date              -- [X_ñú
         , xch.payment_frequency       = io_contract_data_rec.payment_frequency          -- x¥ñ
         , xch.payment_type            = io_contract_data_rec.payment_type               -- px
         , xch.payment_years           = io_contract_data_rec.payment_years              -- Nx
         , xch.lease_start_date        = io_contract_data_rec.lease_start_date           -- [XJnú
         , xch.lease_end_date          = io_contract_data_rec.lease_end_date             -- [XI¹ú
         , xch.first_payment_date      = io_contract_data_rec.first_payment_date         -- ñx¥ú
         , xch.second_payment_date     = io_contract_data_rec.second_payment_date        -- QñÚx¥ú
         , xch.third_payment_date      = io_contract_data_rec.third_payment_date         -- RñÚÈ~x¥ú
         , xch.start_period_name       = io_contract_data_rec.start_period_name          -- ïpvãïvïvúÔ   
         , xch.lease_payment_flag      = io_contract_data_rec.lease_payment_flag         -- x¥væ®¹tO
         , xch.tax_code                = io_contract_data_rec.tax_code                   -- ÅR[h
         , xch.created_by              = io_contract_data_rec.created_by                 -- ì¬Ò
         , xch.creation_date           = io_contract_data_rec.creation_date              -- ì¬ú
         , xch.last_updated_by         = io_contract_data_rec.last_updated_by            -- ÅIXVÒ
         , xch.last_update_date        = io_contract_data_rec.last_update_date           -- ÅIXVú
         , xch.last_update_login       = io_contract_data_rec.last_update_login          -- ÅIXVÛ¸Þ²Ý
         , xch.request_id              = io_contract_data_rec.request_id                 -- vID
         , xch.program_application_id  = io_contract_data_rec.program_application_id     -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
         , xch.program_id              = io_contract_data_rec.program_id                 -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
         , xch.program_update_date     = io_contract_data_rec.program_update_date        -- ÌßÛ¸Þ×ÑXVú     
    WHERE  xch.contract_header_id      = io_contract_data_rec.contract_header_id         -- _ñàID
    ;
--
  EXCEPTION
--###############################  ÅèáO START   ###################################
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  Åè END   #########################################
--
  END update_co_hed;
  --
  /**********************************************************************************
   * Function Name    : update_co_lin
   * Description      : [X_ñ¾×XV
   ***********************************************************************************/
  PROCEDURE update_co_lin(
    io_contract_data_rec IN OUT NOCOPY cont_lin_data_rtype    -- _ñ¾×îñ
   ,ov_errbuf               OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode              OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg               OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  )
  IS
    -- ===============================
    -- Åè[Jè
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'update_co_lin';   -- vO¼
    -- ===============================
    -- [JÏ
    -- ===============================
    lv_errbuf       VARCHAR2(5000) := NULL;              -- G[EbZ[W
    lv_retcode      VARCHAR2(1)    := cv_status_normal;  -- ^[ER[h
    lv_errmsg       VARCHAR2(5000) := NULL;              -- [U[EG[EbZ[W
    --
    -- ===============================
    -- [Je[u^
    -- ===============================
    TYPE null_check_ttype IS TABLE OF VARCHAR2(5000);
    -- ===============================
    -- [Je[u^Ï
    -- ===============================
    l_null_check_tab   null_check_ttype := null_check_ttype();  -- K{`FbN
    --
  BEGIN
  --
    -- ú»
    ov_errbuf  := NULL;
    ov_retcode := cv_status_normal;
    ov_errmsg  := NULL;
    -- ***************************************************
    -- 1.[X_ñXV
    -- ***************************************************
    --
    UPDATE xxcff_contract_lines xcl  -- [X_ñ¾×e[u
    SET    xcl.contract_line_num           = io_contract_data_rec.contract_line_num           -- _ñ}Ô
         , xcl.contract_status             = io_contract_data_rec.contract_status             -- _ñXe[^X
         , xcl.first_charge                = io_contract_data_rec.first_charge                -- ñz[X¿_[X¿
         , xcl.first_tax_charge            = io_contract_data_rec.first_tax_charge            -- ñÁïÅz_[X¿
         , xcl.first_total_charge          = io_contract_data_rec.first_total_charge          -- ñv[X¿
         , xcl.second_charge               = io_contract_data_rec.second_charge               -- QñÚz[X¿_[X¿
         , xcl.second_tax_charge           = io_contract_data_rec.second_tax_charge           -- QñÚÁïÅz_[X¿
         , xcl.second_total_charge         = io_contract_data_rec.second_total_charge         -- QñÚv[X¿
         , xcl.first_deduction             = io_contract_data_rec.first_deduction             -- ñz[X¿_Tz
         , xcl.first_tax_deduction         = io_contract_data_rec.first_tax_deduction         -- ñÁïÅz_Tz
         , xcl.first_total_deduction       = io_contract_data_rec.first_total_deduction       -- ñvTz
         , xcl.second_deduction            = io_contract_data_rec.second_deduction            -- QñÚÈ~z[X¿_Tz
         , xcl.second_tax_deduction        = io_contract_data_rec.second_tax_deduction        -- QñÚÈ~ÁïÅz_Tz
         , xcl.second_total_deduction      = io_contract_data_rec.second_total_deduction      -- QñÚÈ~vTz
         , xcl.gross_charge                = io_contract_data_rec.gross_charge                -- z[X¿_[X¿
         , xcl.gross_tax_charge            = io_contract_data_rec.gross_tax_charge            -- zÁïÅz_[X¿
         , xcl.gross_total_charge          = io_contract_data_rec.gross_total_charge          -- zv_[X¿
         , xcl.gross_deduction             = io_contract_data_rec.gross_deduction             -- z[X¿_Tz
         , xcl.gross_tax_deduction         = io_contract_data_rec.gross_tax_deduction         -- zÁïÅ_Tz
         , xcl.gross_total_deduction       = io_contract_data_rec.gross_total_deduction       -- zv_Tz
         , xcl.lease_kind                  = io_contract_data_rec.lease_kind                  -- [XíÞ
         , xcl.estimated_cash_price        = io_contract_data_rec.estimated_cash_price        -- ©Ï»àwüàz
         , xcl.present_value_discount_rate = io_contract_data_rec.present_value_discount_rate -- »à¿lø¦
         , xcl.present_value               = io_contract_data_rec.present_value               -- »à¿l
         , xcl.life_in_months              = io_contract_data_rec.life_in_months              -- @èÏpN
         , xcl.original_cost               = io_contract_data_rec.original_cost               -- æ¾¿i
         , xcl.calc_interested_rate        = io_contract_data_rec.calc_interested_rate        -- vZq¦
         , xcl.object_header_id            = io_contract_data_rec.object_header_id            -- ¨àid
         , xcl.asset_category              = io_contract_data_rec.asset_category              -- YíÞ
         , xcl.expiration_date             = io_contract_data_rec.expiration_date             -- ¹ú
         , xcl.cancellation_date           = io_contract_data_rec.cancellation_date           -- rðñú
         , xcl.vd_if_date                  = io_contract_data_rec.vd_if_date                  -- [X_ñîñAgú
         , xcl.info_sys_if_date            = io_contract_data_rec.info_sys_if_date            -- [XÇîñAgú
         , xcl.first_installation_address  = io_contract_data_rec.first_installation_address  -- ñÝuê
         , xcl.first_installation_place    = io_contract_data_rec.first_installation_place    -- ñÝuæ
-- 2013/06/26 Ver.1.1 T.Nakano ADD Start
         , xcl.tax_code                    = io_contract_data_rec.tax_code                    -- ÅàR[h
-- 2013/06/26 Ver.1.1 T.Nakano ADD End
-- Ver.1.2 ADD Start
         , original_cost_type1             = io_contract_data_rec.original_cost_type1         -- [XÂz_´_ñ
         , original_cost_type2             = io_contract_data_rec.original_cost_type2         -- [XÂz_Ä[X
-- Ver.1.2 ADD End
         , xcl.created_by                  = io_contract_data_rec.created_by                  -- ì¬Ò
         , xcl.creation_date               = io_contract_data_rec.creation_date               -- ì¬ú
         , xcl.last_updated_by             = io_contract_data_rec.last_updated_by             -- ÅIXVÒ
         , xcl.last_update_date            = io_contract_data_rec.last_update_date            -- ÅIXVú
         , xcl.last_update_login           = io_contract_data_rec.last_update_login           -- ÅIXVÛ¸Þ²Ý
         , xcl.request_id                  = io_contract_data_rec.request_id                  -- vID
         , xcl.program_application_id      = io_contract_data_rec.program_application_id      -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
         , xcl.program_id                  = io_contract_data_rec.program_id                  -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
         , xcl.program_update_date         = io_contract_data_rec.program_update_date         -- ÌßÛ¸Þ×ÑXVú
    WHERE  xcl.contract_header_id          = io_contract_data_rec.contract_header_id          -- _ñàID
      AND  xcl.contract_line_id            = io_contract_data_rec.contract_line_id            -- _ñ¾×àID
    ;
--
  EXCEPTION
--###############################  ÅèáO START   ###################################
    -- *** ¤ÊáOnh ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ¤ÊÖOTHERSáOnh ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERSáOnh ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--###################################  Åè END   #########################################
--
  END update_co_lin;
  --
END XXCFF_COMMON4_PKG;
/