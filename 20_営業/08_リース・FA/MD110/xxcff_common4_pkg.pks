create or replace PACKAGE XXCFF_COMMON4_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff_common4_pkg(spec)
 * Description      : [X_ñÖA¤ÊÖ
 * MD.050           : Èµ
 * Version          : 1.3
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
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-19    1.0   SCSâEèS       VKì¬
 *  2008-12-22    1.1   SCSâEèS       ÅàR[hðÇÁ
 *  2013-06-25    1.2   SCSKìOç      [E_{Ò®_10871]ÁïÅÅÎ
 *  2016-08-10    1.3   SCSKmØdl      [E_{Ò®_13658]©Ì@ÏpNÏXÎ
 *
 *****************************************************************************************/
--
--#######################  R[h^é¾ START   #######################
--
  -- [X_ñîñ
  TYPE cont_hed_data_rtype IS RECORD(
     contract_header_id         xxcff_contract_headers.contract_header_id%TYPE         -- _ñàID
   , contract_number            xxcff_contract_headers.contract_number%TYPE            -- _ñÔ
   , lease_class                xxcff_contract_headers.lease_class%TYPE                -- [XíÊ
   , lease_type                 xxcff_contract_headers.lease_type%TYPE                 -- [Xæª
   , lease_company              xxcff_contract_headers.lease_company%TYPE              -- [XïÐ
   , re_lease_times             xxcff_contract_headers.re_lease_times%TYPE DEFAULT 0   -- Ä[Xñ
   , comments                   xxcff_contract_headers.comments%TYPE                   -- ¼
   , contract_date              xxcff_contract_headers.contract_date%TYPE              -- [X_ñú
   , payment_frequency          xxcff_contract_headers.payment_frequency%TYPE          -- x¥ñ
   , payment_type               xxcff_contract_headers.payment_type%TYPE               -- px
   , payment_years              xxcff_contract_headers.payment_years%TYPE              -- Nx
   , lease_start_date           xxcff_contract_headers.lease_start_date%TYPE           -- [XJnú
   , lease_end_date             xxcff_contract_headers.lease_end_date%TYPE             -- [XI¹ú
   , first_payment_date         xxcff_contract_headers.first_payment_date%TYPE         -- ñx¥ú
   , second_payment_date        xxcff_contract_headers.second_payment_date%TYPE        -- QñÚx¥ú
   , third_payment_date         xxcff_contract_headers.third_payment_date%TYPE         -- RñÚÈ~x¥ú
   , start_period_name          xxcff_contract_headers.start_period_name%TYPE          -- ïpvãïvïvúÔ   
   , lease_payment_flag         xxcff_contract_headers.lease_payment_flag%TYPE         -- x¥væ®¹tO
   , tax_code                   xxcff_contract_headers.tax_code%TYPE                   -- ÅR[h
   , created_by                 xxcff_contract_headers.created_by%TYPE                 -- ì¬Ò
   , creation_date              xxcff_contract_headers.creation_date%TYPE              -- ì¬ú
   , last_updated_by            xxcff_contract_headers.last_updated_by%TYPE            -- ÅIXVÒ
   , last_update_date           xxcff_contract_headers.last_update_date%TYPE           -- ÅIXVú
   , last_update_login          xxcff_contract_headers.last_update_login%TYPE          -- ÅIXVÛ¸Þ²Ý
   , request_id                 xxcff_contract_headers.request_id%TYPE                 -- vID
   , program_application_id     xxcff_contract_headers.program_application_id%TYPE     -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
   , program_id                 xxcff_contract_headers.program_id%TYPE                 -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
   , program_update_date        xxcff_contract_headers.program_update_date%TYPE        -- ÌßÛ¸Þ×ÑXVú
  );
  --    
  -- [X_ñ¾×îñ
  TYPE cont_lin_data_rtype IS RECORD(
     contract_line_id           xxcff_contract_lines.contract_line_id%TYPE             -- _ñà¾×ID
   , contract_header_id         xxcff_contract_lines.contract_header_id%TYPE           -- _ñàID
   , contract_line_num          xxcff_contract_lines.contract_line_num%TYPE            -- _ñ}Ô
-- 2013/06/25 Ver.1.2 T.Nakano ADD Start
   , tax_code                   xxcff_contract_lines.tax_code%TYPE                     -- ÅàR[h
-- 2013/06/25 Ver.1.2 T.Nakano ADD End
   , contract_status            xxcff_contract_lines.contract_status%TYPE              -- _ñXe[^X
   , first_charge               xxcff_contract_lines.first_charge%TYPE                 -- ñz[X¿_[X¿
   , first_tax_charge           xxcff_contract_lines.first_tax_charge%TYPE             -- ñÁïÅz_[X¿
   , first_total_charge         xxcff_contract_lines.first_total_charge%TYPE           -- ñv[X¿
   , second_charge              xxcff_contract_lines.second_charge%TYPE                -- QñÚz[X¿_[X¿
   , second_tax_charge          xxcff_contract_lines.second_tax_charge%TYPE            -- QñÚÁïÅz_[X¿
   , second_total_charge        xxcff_contract_lines.second_total_charge%TYPE          -- QñÚv[X¿
   , first_deduction            xxcff_contract_lines.first_deduction%TYPE              -- ñz[X¿_Tz
   , first_tax_deduction        xxcff_contract_lines.first_tax_deduction%TYPE          -- ñÁïÅz_Tz
   , first_total_deduction      xxcff_contract_lines.first_total_deduction%TYPE        -- ñvTz
   , second_deduction           xxcff_contract_lines.second_deduction%TYPE             -- QñÚÈ~z[X¿_Tz
   , second_tax_deduction       xxcff_contract_lines.second_tax_deduction%TYPE         -- QñÚÈ~ÁïÅz_Tz
   , second_total_deduction     xxcff_contract_lines.second_total_deduction%TYPE       -- QñÚÈ~vTz
   , gross_charge               xxcff_contract_lines.gross_charge%TYPE                 -- z[X¿_[X¿
   , gross_tax_charge           xxcff_contract_lines.gross_tax_charge%TYPE             -- zÁïÅz_[X¿
   , gross_total_charge         xxcff_contract_lines.gross_total_charge%TYPE           -- zv_[X¿
   , gross_deduction            xxcff_contract_lines.gross_deduction%TYPE              -- z[X¿_Tz
   , gross_tax_deduction        xxcff_contract_lines.gross_tax_deduction%TYPE          -- zÁïÅ_Tz
   , gross_total_deduction      xxcff_contract_lines.gross_total_deduction%TYPE        -- zv_Tz
   , lease_kind                 xxcff_contract_lines.lease_kind%TYPE                   -- [XíÞ
   , estimated_cash_price       xxcff_contract_lines.estimated_cash_price%TYPE         -- ©Ï»àwüàz
   , present_value_discount_rate xxcff_contract_lines.present_value_discount_rate%TYPE -- »à¿lø¦
   , present_value              xxcff_contract_lines.present_value%TYPE                -- »à¿l
   , life_in_months             xxcff_contract_lines.life_in_months%TYPE               -- @èÏpN
   , original_cost              xxcff_contract_lines.original_cost%TYPE                -- æ¾¿i
   , calc_interested_rate       xxcff_contract_lines.calc_interested_rate%TYPE         -- vZq¦
   , object_header_id           xxcff_contract_lines.object_header_id%TYPE             -- ¨àid
   , asset_category             xxcff_contract_lines.asset_category%TYPE               -- YíÞ
   , expiration_date            xxcff_contract_lines.expiration_date%TYPE              -- ¹ú
   , cancellation_date          xxcff_contract_lines.cancellation_date%TYPE            -- rðñú
   , vd_if_date                 xxcff_contract_lines.vd_if_date%TYPE                   -- [X_ñîñAgú
   , info_sys_if_date           xxcff_contract_lines.info_sys_if_date%TYPE             -- [XÇîñAgú
   , first_installation_address xxcff_contract_lines.first_installation_address%TYPE   -- ñÝuê
   , first_installation_place   xxcff_contract_lines.first_installation_place%TYPE     -- ñÝuæ
-- Ver.1.3 ADD Start
   , original_cost_type1        xxcff_contract_lines.original_cost_type1%TYPE          -- [XÂz_´_ñ
   , original_cost_type2        xxcff_contract_lines.original_cost_type2%TYPE          -- [XÂz_Ä[X
-- Ver.1.3 ADD End
   , created_by                 xxcff_contract_lines.created_by%TYPE                   -- ì¬Ò
   , creation_date              xxcff_contract_lines.creation_date%TYPE                -- ì¬ú
   , last_updated_by            xxcff_contract_lines.last_updated_by%TYPE              -- ÅIXVÒ
   , last_update_date           xxcff_contract_lines.last_update_date%TYPE             -- ÅIXVú
   , last_update_login          xxcff_contract_lines.last_update_login%TYPE            -- ÅIXVÛ¸Þ²Ý
   , request_id                 xxcff_contract_lines.request_id%TYPE                   -- vID
   , program_application_id     xxcff_contract_lines.program_application_id%TYPE       -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID
   , program_id                 xxcff_contract_lines.program_id%TYPE                   -- ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID
   , program_update_date        xxcff_contract_lines.program_update_date%TYPE          -- ÌßÛ¸Þ×ÑXVú
  );
  --
  -- [X_ñðîñ
  TYPE cont_his_data_rtype IS RECORD(
     accounting_date            xxcff_contract_histories.accounting_date%TYPE          -- vãú
   , accounting_if_flag         xxcff_contract_histories.accounting_if_flag%TYPE       -- ïvIFtO
   , description                xxcff_contract_histories.description%TYPE              -- Ev
  );
  --
  --#######################  vV[Wé¾ START   #######################
  --
  --
  -- [X_ño^Ö
  PROCEDURE insert_co_hed(
    io_contract_data_rec    IN OUT NOCOPY cont_hed_data_rtype    -- _ñîñ
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  );
  --
  -- [X_ñ¾×o^Ö
  PROCEDURE insert_co_lin(
    io_contract_data_rec    IN OUT NOCOPY cont_lin_data_rtype    -- _ñ¾×îñ
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  );
 --
  -- [X_ñðo^Ö
  PROCEDURE insert_co_his(
    io_contract_lin_data_rec IN OUT NOCOPY cont_lin_data_rtype   -- _ñ¾×îñ
   ,io_contract_his_data_rec IN OUT NOCOPY cont_his_data_rtype   -- _ñðîñ
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  );
  --
  -- [X_ñXVÖ
  PROCEDURE update_co_hed(
    io_contract_data_rec    IN OUT NOCOPY cont_hed_data_rtype    -- _ñîñ
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  );
  --
  -- [X_ñ¾×XVÖ
  PROCEDURE update_co_lin(
    io_contract_data_rec    IN OUT NOCOPY cont_lin_data_rtype    -- _ñ¾×îñ
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- G[EbZ[W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ^[ER[h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- [U[EG[EbZ[W
  );
  --
  --
END XXCFF_COMMON4_PKG
;
/