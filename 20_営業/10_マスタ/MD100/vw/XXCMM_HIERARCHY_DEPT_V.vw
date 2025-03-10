/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcmm_hierarchy_dept_v
 * Description     : åKwr[
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *                1.0   K.Okuyama        VKì¬
 *  2009/04/20    1.1   Y.Kuboshima      áQT1_0590Î
 *  2009/10/01    1.2   S.Niki           ¤ÊÛèI_E_542Î
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW apps.xxcmm_hierarchy_dept_v
(
  cur_dpt_cd,
  cur_dpt_lv,
  cur_dpt_fvl_name,
  dpt1_cd,
  dpt1_name,
  dpt1_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  dpt1_sort_num,
  dpt1_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  dpt1_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  dpt1_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  dpt1_div,
  dpt2_cd,
  dpt2_name,
  dpt2_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  dpt2_sort_num,
  dpt2_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  dpt2_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  dpt2_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  dpt2_div,
  dpt3_cd,
  dpt3_name,
  dpt3_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  dpt3_sort_num,
  dpt3_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  dpt3_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  dpt3_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  dpt3_div,
  dpt4_cd,
  dpt4_name,
  dpt4_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  dpt4_sort_num,
  dpt4_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  dpt4_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  dpt4_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  dpt4_div,
  dpt5_cd,
  dpt5_name,
  dpt5_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  dpt5_sort_num,
  dpt5_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  dpt5_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  dpt5_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  dpt5_div,
  dpt6_cd,
  dpt6_name,
  dpt6_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  dpt6_sort_num,
  dpt6_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  dpt6_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  dpt6_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  dpt6_div,
  flex_value_set_id,
  creation_date,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  last_update_date,
--  hierarchy_sort_key
  last_update_date
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
) AS 
SELECT
  tbl.cur_dpt_cd,
  tbl.cur_dpt_lv,
  tbl.cur_dpt_fvl_name,
  tbl.dpt1_cd,
  tbl.dpt1_name,
  tbl.dpt1_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  tbl.dpt1_sort_num,
  tbl.dpt1_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  tbl.dpt1_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  tbl.dpt1_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  tbl.dpt1_div,
  tbl.dpt2_cd,
  tbl.dpt2_name,
  tbl.dpt2_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  tbl.dpt2_sort_num,
  tbl.dpt2_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  tbl.dpt2_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  tbl.dpt2_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  tbl.dpt2_div,
  tbl.dpt3_cd,
  tbl.dpt3_name,
  tbl.dpt3_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  tbl.dpt3_sort_num,
  tbl.dpt3_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  tbl.dpt3_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  tbl.dpt3_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  tbl.dpt3_div,
  tbl.dpt4_cd,
  tbl.dpt4_name,
  tbl.dpt4_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  tbl.dpt4_sort_num,
  tbl.dpt4_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  tbl.dpt4_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  tbl.dpt4_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  tbl.dpt4_div,
  tbl.dpt5_cd,
  tbl.dpt5_name,
  tbl.dpt5_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  tbl.dpt5_sort_num,
  tbl.dpt5_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  tbl.dpt5_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  tbl.dpt5_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  tbl.dpt5_div,
  tbl.dpt6_cd,
  tbl.dpt6_name,
  tbl.dpt6_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--  tbl.dpt6_sort_num,
  tbl.dpt6_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
  tbl.dpt6_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
  tbl.dpt6_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
  tbl.dpt6_div,
  tbl.flex_value_set_id,
  tbl.creation_date,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--   tbl.last_update_date,
--   ( '01' ||
--     LPAD(NVL(tbl.dpt1_sort_num,'999'),3,'0') ||
--     LPAD(tbl.dpt1_cd,4,'0') || 
--     '02' ||
--     LPAD(NVL(tbl.dpt2_sort_num,'999'),3,'0') ||
--     LPAD(tbl.dpt2_cd,4,'0') || 
--     '03' ||
--     LPAD(NVL(tbl.dpt3_sort_num,'999'),3,'0') ||
--     LPAD(tbl.dpt3_cd,4,'0') || 
--     '04' ||
--     LPAD(NVL(tbl.dpt4_sort_num,'999'),3,'0') ||
--     LPAD(tbl.dpt4_cd,4,'0') || 
--     '05' ||
--     LPAD(NVL(tbl.dpt5_sort_num,'999'),3,'0') ||
--     LPAD(tbl.dpt5_cd,4,'0') || 
--     '06' ||
--     LPAD(NVL(tbl.dpt6_sort_num,'999'),3,'0') ||
--     LPAD(tbl.dpt6_cd,4,'0')
--   ) AS  hierarchy_sort_key
  tbl.last_update_date
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
FROM
(
  SELECT
    dph.fvl_cd                        AS  cur_dpt_cd,
    dph.fvl_level                     AS  cur_dpt_lv,
    dph.fvl_name                      AS  cur_dpt_fvl_name,
    /* PKwÚ */
    dph.dpt1_cd,
    dph.dpt1_name,
    dph.dpt1_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--     dph.dpt1_sort_num,
    dph.dpt1_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
    dph.dpt1_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
    dph.dpt1_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
    dph.dpt1_div,
    /* QKwÚ */
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_cd
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_cd
      ELSE
        dph.dpt1_cd
      END
    END                               AS  dpt2_cd,
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_name
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_name
      ELSE
        dph.dpt1_name
      END
    END                               AS  dpt2_name,
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_abbreviate
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_abbreviate
      ELSE
        dph.dpt1_abbreviate
      END
    END                               AS  dpt2_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--     CASE WHEN dph.dpt2_cd IS NULL THEN
--       dph.dpt1_sort_num
--     ELSE
--       CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
--         dph.dpt2_sort_num
--       ELSE
--         dph.dpt1_sort_num
--       END
--     END                               AS  dpt2_sort_num,
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_start_date_active
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_start_date_active
      ELSE
        dph.dpt1_start_date_active
      END
    END                               AS  dpt2_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_old_cd
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_old_cd
      ELSE
        dph.dpt1_old_cd
      END
    END                               AS  dpt2_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_new_cd
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_new_cd
      ELSE
        dph.dpt1_new_cd
      END
    END                               AS  dpt2_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_div
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_div
      ELSE
        dph.dpt1_div
      END
    END                               AS  dpt2_div,
    /* RKwÚ */
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_cd
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_cd
      ELSE
        dph.dpt2_cd
      END
    END                               AS  dpt3_cd,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_name
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_name
      ELSE
        dph.dpt2_name
      END
    END                               AS  dpt3_name,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_abbreviate
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_abbreviate
      ELSE
        dph.dpt2_abbreviate
      END
    END                               AS  dpt3_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--     CASE WHEN dph.dpt3_cd IS NULL THEN
--       dph.dpt1_sort_num
--     ELSE
--       CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
--         dph.dpt3_sort_num
--       ELSE
--         dph.dpt2_sort_num
--       END
--      END                               AS  dpt3_sort_num,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_start_date_active
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_start_date_active
      ELSE
        dph.dpt2_start_date_active
      END
    END                               AS  dpt3_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_old_cd
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_old_cd
      ELSE
        dph.dpt2_old_cd
      END
    END                               AS  dpt3_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_new_cd
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_new_cd
      ELSE
        dph.dpt2_new_cd
      END
    END                               AS  dpt3_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_div
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_div
      ELSE
        dph.dpt2_div
      END
    END                               AS  dpt3_div,
    /* SKwÚ */
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_cd
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_cd
        ELSE
          dph.dpt1_cd
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_cd
      ELSE
        dph.dpt3_cd
      END
    END                               AS  dpt4_cd,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_name
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_name
        ELSE
          dph.dpt1_name
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_name
      ELSE
        dph.dpt3_name
      END
    END                               AS  dpt4_name,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_abbreviate
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_abbreviate
        ELSE
          dph.dpt1_abbreviate
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_abbreviate
      ELSE
        dph.dpt3_abbreviate
      END
    END                               AS  dpt4_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--     CASE WHEN dph.dpt4_cd IS NULL THEN
--       CASE WHEN dph.dpt2_cd IS NULL THEN
--         dph.dpt1_sort_num
--       ELSE
--         CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
--           dph.dpt2_sort_num
--         ELSE
--           dph.dpt1_sort_num
--         END
--       END
--     ELSE
--       CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
--         dph.dpt4_sort_num
--       ELSE
--         dph.dpt3_sort_num
--       END
--     END                               AS  dpt4_sort_num,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_start_date_active
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_start_date_active
        ELSE
          dph.dpt1_start_date_active
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_start_date_active
      ELSE
        dph.dpt3_start_date_active
      END
    END                               AS  dpt4_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_old_cd
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_old_cd
        ELSE
          dph.dpt1_old_cd
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_old_cd
      ELSE
        dph.dpt3_old_cd
      END
    END                               AS  dpt4_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_new_cd
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_new_cd
        ELSE
          dph.dpt1_new_cd
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_new_cd
      ELSE
        dph.dpt3_new_cd
      END
    END                               AS  dpt4_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_div
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_div
        ELSE
          dph.dpt1_div
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_div
      ELSE
        dph.dpt3_div
      END
    END                               AS  dpt4_div,
    /* TKwÚ */
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_cd
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_cd
        ELSE
          dph.dpt2_cd
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_cd
      ELSE
        dph.dpt4_cd
      END
    END                               AS  DPT5_CD,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_name
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_name
        ELSE
          dph.dpt2_name
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_name
      ELSE
        dph.dpt4_name
      END
    END                               AS  dpt5_name,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_abbreviate
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_abbreviate
        ELSE
          dph.dpt2_abbreviate
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_abbreviate
      ELSE
        dph.dpt4_abbreviate
      END
    END                               AS  dpt5_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--     CASE WHEN dph.dpt5_cd IS NULL THEN
--       CASE WHEN dph.dpt3_cd IS NULL THEN
--         dph.dpt1_sort_num
--       ELSE
--         CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
--           dph.dpt3_sort_num
--         ELSE
--           dph.dpt2_sort_num
--         END
--       END
--     ELSE
--       CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
--         dph.dpt5_sort_num
--       ELSE
--         dph.dpt4_sort_num
--       END
--     END                               AS  dpt5_sort_num,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_start_date_active
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_start_date_active
        ELSE
          dph.dpt2_start_date_active
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_start_date_active
      ELSE
        dph.dpt4_start_date_active
      END
    END                               AS  dpt5_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_old_cd
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_old_cd
        ELSE
          dph.dpt2_old_cd
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_old_cd
      ELSE
        dph.dpt4_old_cd
      END
    END                               AS  dpt5_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_new_cd
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_new_cd
        ELSE
          dph.dpt2_new_cd
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_new_cd
      ELSE
        dph.dpt4_new_cd
      END
    END                               AS  dpt5_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_div
      ELSE
        CASE when dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_div
        ELSE
          dph.dpt2_div
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_div
      ELSE
        dph.dpt4_div
      END
    END                               AS  dpt5_div,
    /* UKwÚ */
    NVL(dph.dpt6_cd,dph.fvl_cd)             AS  dpt6_cd,
    NVL(dph.dpt6_name,dph.attribute4)       AS  dpt6_name,
    NVL(dph.dpt6_abbreviate,dph.attribute5) AS  dpt6_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--     NVL(dph.dpt6_sort_num,dph.attribute6)   AS  dpt6_sort_num,
    NVL(dph.dpt6_start_date_active,dph.attribute6)   AS  dpt6_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
    NVL(dph.dpt6_old_cd,dph.attribute7)     AS  dpt6_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
    NVL(dph.dpt6_new_cd,dph.attribute9)     AS  dpt6_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
    NVL(dph.dpt6_div,dph.attribute8)        AS  dpt6_div,
    dph.flex_value_set_id,
    dph.creation_date,
    dph.last_update_date
  FROM
  (
    SELECT
      dpt.flex_value        AS  fvl_cd,
      dpt.description       AS  fvl_name,
      dpt.attribute4        AS  attribute4,
      dpt.attribute5        AS  attribute5,
      dpt.attribute6        AS  attribute6,
      dpt.attribute7        AS  attribute7,
      dpt.attribute8        AS  attribute8,
-- 2009/10/01 I_E_542 add atart by Shigeto.Niki
      dpt.attribute9        AS  attribute9,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki 
      dpt.dpt_lelel         AS  fvl_level,
      /* PKwÚ */
      SUBSTR(
        dpt.dpt_cd_root,
        INSTR(dpt.dpt_cd_root,'\',1,1)+1,
        INSTR(dpt.dpt_cd_root,'\',1,2)-INSTR(dpt.dpt_cd_root,'\',1,1)-1
      )                     AS  dpt1_cd,
      SUBSTR(
        dpt.fvl_name_root,
        INSTR(dpt.fvl_name_root,'\',1,1)+1,
        INSTR(dpt.fvl_name_root,'\',1,2)-INSTR(dpt.fvl_name_root,'\',1,1)-1
      )                     AS  fvl1_name,
      SUBSTR(
        dpt.dpt_name_root,
        INSTR(dpt.dpt_name_root,'\',1,1)+1,
        INSTR(dpt.dpt_name_root,'\',1,2)-INSTR(dpt.dpt_name_root,'\',1,1)-1
      )                     AS  dpt1_name,
      SUBSTR(
        dpt.dpt_abbreviate_root,
        INSTR(dpt.dpt_abbreviate_root,'\',1,1)+1,
        INSTR(dpt.dpt_abbreviate_root,'\',1,2)-INSTR(dpt.dpt_abbreviate_root,'\',1,1)-1
      )                     AS  dpt1_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--       SUBSTR(
--         dpt.dpt_sort_num_root,
--         INSTR(dpt.dpt_sort_num_root,'\',1,1)+1,
--         INSTR(dpt.dpt_sort_num_root,'\',1,2)-INSTR(dpt.dpt_sort_num_root,'\',1,1)-1
--       )                     AS  dpt1_sort_num,
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,1)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,2)-INSTR(dpt.dpt_start_date_active_root,'\',1,1)-1
      )                     AS  dpt1_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,1)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,2)-INSTR(dpt.dpt_old_cd_root,'\',1,1)-1
      )                     AS  dpt1_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,1)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,2)-INSTR(dpt.dpt_new_cd_root,'\',1,1)-1
      )                     AS  dpt1_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,1)+1,
        INSTR(dpt.dpt_div_root,'\',1,2)-INSTR(dpt.dpt_div_root,'\',1,1)-1
      )                     AS  dpt1_div,
      /* QKwÚ */
      SUBSTR(
        dpt.dpt_cd_root,
        INSTR(dpt.dpt_cd_root,'\',1,2)+1,
        INSTR(dpt.dpt_cd_root,'\',1,3)-INSTR(dpt.dpt_cd_root,'\',1,2)-1
      )                     AS  dpt2_cd,
      SUBSTR(
        dpt.fvl_name_root,
        INSTR(dpt.fvl_name_root,'\',1,2)+1,
        INSTR(dpt.fvl_name_root,'\',1,3)-INSTR(dpt.fvl_name_root,'\',1,2)-1
      )                     AS  fvl2_name,
      SUBSTR(
        dpt.dpt_name_root,
        INSTR(dpt.dpt_name_root,'\',1,2)+1,
        INSTR(dpt.dpt_name_root,'\',1,3)-INSTR(dpt.dpt_name_root,'\',1,2)-1
      )                     AS  dpt2_name,
      SUBSTR(
        dpt.dpt_abbreviate_root,
        INSTR(dpt.dpt_abbreviate_root,'\',1,2)+1,
        INSTR(dpt.dpt_abbreviate_root,'\',1,3)-INSTR(dpt.dpt_abbreviate_root,'\',1,2)-1
      )                     AS  dpt2_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--       SUBSTR(
--         dpt.dpt_sort_num_root,
--         INSTR(dpt.dpt_sort_num_root,'\',1,2)+1,
--         INSTR(dpt.dpt_sort_num_root,'\',1,3)-INSTR(dpt.dpt_sort_num_root,'\',1,2)-1
--       )                     AS  dpt2_sort_num,
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,2)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,3)-INSTR(dpt.dpt_start_date_active_root,'\',1,2)-1
      )                     AS  dpt2_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,2)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,3)-INSTR(dpt.dpt_old_cd_root,'\',1,2)-1
      )                     AS  dpt2_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,2)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,3)-INSTR(dpt.dpt_new_cd_root,'\',1,2)-1
      )                     AS  dpt2_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,2)+1,
        INSTR(dpt.dpt_div_root,'\',1,3)-INSTR(dpt.dpt_div_root,'\',1,2)-1
      )                     AS  dpt2_div,
      /* RKwÚ */
      SUBSTR(
        dpt.dpt_cd_root,
        INSTR(dpt.dpt_cd_root,'\',1,3)+1,
        INSTR(dpt.dpt_cd_root,'\',1,4)-INSTR(dpt.dpt_cd_root,'\',1,3)-1
      )                     AS  dpt3_cd,
      SUBSTR(
        dpt.fvl_name_root,
        INSTR(dpt.fvl_name_root,'\',1,3)+1,
        INSTR(dpt.fvl_name_root,'\',1,4)-INSTR(dpt.fvl_name_root,'\',1,3)-1
      )                     AS  fvl3_name,
      SUBSTR(
        dpt.dpt_name_root,
        INSTR(dpt.dpt_name_root,'\',1,3)+1,
        INSTR(dpt.dpt_name_root,'\',1,4)-INSTR(dpt.dpt_name_root,'\',1,3)-1
      )                     AS  dpt3_name,
      SUBSTR(
        dpt.dpt_abbreviate_root,
        INSTR(dpt.dpt_abbreviate_root,'\',1,3)+1,
        INSTR(dpt.dpt_abbreviate_root,'\',1,4)-INSTR(dpt.dpt_abbreviate_root,'\',1,3)-1
      )                     AS  dpt3_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--       SUBSTR(
--         dpt.dpt_sort_num_root,
--         INSTR(dpt.dpt_sort_num_root,'\',1,3)+1,
--         INSTR(dpt.dpt_sort_num_root,'\',1,4)-INSTR(dpt.dpt_sort_num_root,'\',1,3)-1
--       )                     AS  dpt3_sort_num,
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,3)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,4)-INSTR(dpt.dpt_start_date_active_root,'\',1,3)-1
      )                     AS  dpt3_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,3)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,4)-INSTR(dpt.dpt_old_cd_root,'\',1,3)-1
      )                     AS  dpt3_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,3)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,4)-INSTR(dpt.dpt_new_cd_root,'\',1,3)-1
      )                     AS  dpt3_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,3)+1,
        INSTR(dpt.dpt_div_root,'\',1,4)-INSTR(dpt.dpt_div_root,'\',1,3)-1
      )                     AS  dpt3_div,
      /* SKwÚ */
      SUBSTR(
        dpt.dpt_cd_root,
        INSTR(dpt.dpt_cd_root,'\',1,4)+1,
        INSTR(dpt.dpt_cd_root,'\',1,5)-INSTR(dpt.dpt_cd_root,'\',1,4)-1
      )                     AS  dpt4_cd,
      SUBSTR(
        dpt.fvl_name_root,
        INSTR(dpt.fvl_name_root,'\',1,4)+1,
        INSTR(dpt.fvl_name_root,'\',1,5)-INSTR(dpt.fvl_name_root,'\',1,4)-1
      )                     AS  fvl4_name,
      SUBSTR(
        dpt.dpt_name_root,
        INSTR(dpt.dpt_name_root,'\',1,4)+1,
        INSTR(dpt.dpt_name_root,'\',1,5)-INSTR(dpt.dpt_name_root,'\',1,4)-1
      )                     AS  dpt4_name,
      SUBSTR(
        dpt.dpt_abbreviate_root,
        INSTR(dpt.dpt_abbreviate_root,'\',1,4)+1,
        INSTR(dpt.dpt_abbreviate_root,'\',1,5)-INSTR(dpt.dpt_abbreviate_root,'\',1,4)-1
      )                     AS  dpt4_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--       SUBSTR(
--         dpt.dpt_sort_num_root,
--         INSTR(dpt.dpt_sort_num_root,'\',1,4)+1,
--         INSTR(dpt.dpt_sort_num_root,'\',1,5)-INSTR(dpt.dpt_sort_num_root,'\',1,4)-1
--       )                     AS  dpt4_sort_num,
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,4)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,5)-INSTR(dpt.dpt_start_date_active_root,'\',1,4)-1
      )                     AS  dpt4_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,4)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,5)-INSTR(dpt.dpt_old_cd_root,'\',1,4)-1
      )                     AS  dpt4_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,4)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,5)-INSTR(dpt.dpt_new_cd_root,'\',1,4)-1
      )                     AS  dpt4_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,4)+1,
        INSTR(dpt.dpt_div_root,'\',1,5)-INSTR(dpt.dpt_div_root,'\',1,4)-1
      )                     AS  dpt4_div,
      /* TKwÚ */
      SUBSTR(
        dpt.dpt_cd_root,
        INSTR(dpt.dpt_cd_root,'\',1,5)+1,
        INSTR(dpt.dpt_cd_root,'\',1,6)-INSTR(dpt.dpt_cd_root,'\',1,5)-1
      )                     AS  dpt5_cd,
      SUBSTR(
        dpt.fvl_name_root,
        INSTR(dpt.fvl_name_root,'\',1,5)+1,
        INSTR(dpt.fvl_name_root,'\',1,6)-INSTR(dpt.fvl_name_root,'\',1,5)-1
      )                     AS  fvl5_name,
      SUBSTR(
        dpt.dpt_name_root,
        INSTR(dpt.dpt_name_root,'\',1,5)+1,
        INSTR(dpt.dpt_name_root,'\',1,6)-INSTR(dpt.dpt_name_root,'\',1,5)-1
      )                     AS  dpt5_name,
      SUBSTR(
        dpt.dpt_abbreviate_root,
        INSTR(dpt.dpt_abbreviate_root,'\',1,5)+1,
        INSTR(dpt.dpt_abbreviate_root,'\',1,6)-INSTR(dpt.dpt_abbreviate_root,'\',1,5)-1
      )                     AS  dpt5_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--       SUBSTR(
--         dpt.dpt_sort_num_root,
--         INSTR(dpt.dpt_sort_num_root,'\',1,5)+1,
--         INSTR(dpt.dpt_sort_num_root,'\',1,6)-INSTR(dpt.dpt_sort_num_root,'\',1,5)-1
--       )                     AS  dpt5_sort_num,
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,5)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,6)-INSTR(dpt.dpt_start_date_active_root,'\',1,5)-1
      )                     AS  dpt5_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki      
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,5)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,6)-INSTR(dpt.dpt_old_cd_root,'\',1,5)-1
      )                     AS  dpt5_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,5)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,6)-INSTR(dpt.dpt_new_cd_root,'\',1,5)-1
      )                     AS  dpt5_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,5)+1,
        INSTR(dpt.dpt_div_root,'\',1,6)-INSTR(dpt.dpt_div_root,'\',1,5)-1
      )                     AS  dpt5_div,
      /* UKwÚ */
      SUBSTR(
        dpt.dpt_cd_root,
        INSTR(dpt.dpt_cd_root,'\',1,6)+1,
        INSTR(dpt.dpt_cd_root,'\',1,7)-INSTR(dpt.dpt_cd_root,'\',1,6)-1
      )                     AS  dpt6_cd,
      SUBSTR(
        dpt.fvl_name_root,
        INSTR(dpt.fvl_name_root,'\',1,6)+1,
        INSTR(dpt.fvl_name_root,'\',1,7)-INSTR(dpt.fvl_name_root,'\',1,6)-1
      )                     AS  fvl6_name,
      SUBSTR(
        dpt.dpt_name_root,
        INSTR(dpt.dpt_name_root,'\',1,6)+1,
        INSTR(dpt.dpt_name_root,'\',1,7)-INSTR(dpt.dpt_name_root,'\',1,6)-1
      )                     AS  dpt6_name,
      SUBSTR(
        dpt.dpt_abbreviate_root,
        INSTR(dpt.dpt_abbreviate_root,'\',1,6)+1,
        INSTR(dpt.dpt_abbreviate_root,'\',1,7)-INSTR(dpt.dpt_abbreviate_root,'\',1,6)-1
      )                     AS  dpt6_abbreviate,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--       SUBSTR(
--         dpt.dpt_sort_num_root,
--         INSTR(dpt.dpt_sort_num_root,'\',1,6)+1,
--         INSTR(dpt.dpt_sort_num_root,'\',1,7)-INSTR(dpt.dpt_sort_num_root,'\',1,6)-1
--       )                     AS  dpt6_sort_num,
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,6)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,7)-INSTR(dpt.dpt_start_date_active_root,'\',1,6)-1
      )                     AS  dpt6_start_date_active,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,6)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,7)-INSTR(dpt.dpt_old_cd_root,'\',1,6)-1
      )                     AS  dpt6_old_cd,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,6)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,7)-INSTR(dpt.dpt_new_cd_root,'\',1,6)-1
      )                     AS  dpt6_new_cd,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,6)+1,
        INSTR(dpt.dpt_div_root,'\',1,7)-INSTR(dpt.dpt_div_root,'\',1,6)-1
      )                     AS  dpt6_div,
      dpt.flex_value_set_id,
      dpt.creation_date,
      dpt.last_update_date
    FROM
    (
      SELECT
        ffv.flex_value,
        ffv.description,
        ffv.attribute4,
        ffv.attribute5,
        ffv.attribute6,
        ffv.attribute7,
        ffv.attribute8,
        -- 2009/10/01 I_E_542 add atart by Shigeto.Niki
        ffv.attribute9,
        -- 2009/10/01 I_E_542 add end by Shigeto.Niki
        ffv.summary_flag,
        ffv.parent_flex_value,
        LEVEL AS dpt_lelel,
        SYS_CONNECT_BY_PATH(ffv.flex_value, '\') || '\' AS dpt_cd_root,
        SYS_CONNECT_BY_PATH(ffv.description,'\') || '\' AS fvl_name_root,
        SYS_CONNECT_BY_PATH(ffv.attribute4,'\')  || '\' AS dpt_name_root,
        SYS_CONNECT_BY_PATH(ffv.attribute5,'\')  || '\' AS dpt_abbreviate_root,
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
--         SYS_CONNECT_BY_PATH(ffv.attribute6,'\')  || '\' AS dpt_sort_num_root,
        SYS_CONNECT_BY_PATH(ffv.attribute6,'\')  || '\' AS dpt_start_date_active_root,
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
        SYS_CONNECT_BY_PATH(ffv.attribute7,'\')  || '\' AS dpt_old_cd_root,
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
        SYS_CONNECT_BY_PATH(ffv.attribute9,'\')  || '\' AS dpt_new_cd_root,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
        SYS_CONNECT_BY_PATH(ffv.attribute8,'\')  || '\' AS dpt_div_root,
        ffv.flex_value_set_id,
        ffv.creation_date,
        ffv.last_update_date
      FROM
      (
        /* ÅãÊåæ¾ */
        SELECT
          ffvl.flex_value,
          ffvt.description,
          ffvl.summary_flag,
          ffvl.flex_value AS parent_flex_value,
          ffvl.attribute4,
          ffvl.attribute5,
          ffvl.attribute6,
          ffvl.attribute7,
          ffvl.attribute8,
-- 2009/10/01 I_E_542 add atart by Shigeto.Niki
          ffvl.attribute9,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
          ffvl.flex_value_set_id,
          ffvl.creation_date,
          ffvl.last_update_date
        FROM
          fnd_flex_value_sets           ffvs,
          fnd_flex_values               ffvl,
          fnd_flex_values_tl            ffvt
        WHERE
              ffvl.flex_value_set_id    =  ffvs.flex_value_set_id
          AND ffvt.flex_value_id        =  ffvl.flex_value_id
          AND ffvt.language             =  'JA'
          AND ffvl.enabled_flag         =  'Y'
          AND ffvl.summary_flag         =  'Y'
          AND ffvs.flex_value_set_name  =  'XX03_DEPARTMENT'
-- 2009/09/02 áQ0001224 modify start by Yutaka.Kuboshima
-- Æ±út -> cÆúÉÏX
--          AND xxccp_common_pkg2.get_process_date BETWEEN
          AND xxccp_common_pkg2.get_working_day(xxccp_common_pkg2.get_process_date
                                               ,1
                                               ,'SALES_CAL') BETWEEN
-- 2009/09/02 áQ0001224 modify end by Yutaka.Kuboshima
                    NVL(ffvl.start_date_active,to_date('19000101','YYYYMMDD'))
                AND NVL(ffvl.end_date_active,to_date('99991231','YYYYMMDD'))
-- 2009/04/20 áQT1_0590 add start by Yutaka.Kuboshima
          AND ffvl.flex_value          <>  fnd_profile.value('XXCMM1_AFF_DEPT_DUMMY_CD')
-- 2009/04/20 áQT1_0590 add end by Yutaka.Kuboshima
          AND NOT EXISTS(
                SELECT
                  'X'
                FROM
                  fnd_flex_value_norm_hierarchy ffvh
                WHERE
                      ffvh.flex_value_set_id =  ffvl.flex_value_set_id
                  AND ffvl.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high
-- 2009/04/20 áQT1_0590 add start by Yutaka.Kuboshima
                  AND ffvh.range_attribute   =  'P'
              )
          AND EXISTS(
                SELECT 
                  'X'
                FROM
                  fnd_flex_value_norm_hierarchy ffvh2
                WHERE
                      ffvh2.flex_value_set_id = ffvl.flex_value_set_id
                  AND ffvh2.parent_flex_value = ffvl.flex_value
                  AND ffvh2.range_attribute   =  'P'
              )
-- 2009/04/20 áQT1_0590 add end by Yutaka.Kuboshima
        /* ºwåæ¾ */
        UNION ALL
        SELECT
          ffvl.flex_value,
          ffvt.description,
          ffvl.summary_flag,
          ffvh.parent_flex_value,
          ffvl.attribute4,
          ffvl.attribute5,
          ffvl.attribute6,
          ffvl.attribute7,
          ffvl.attribute8,
-- 2009/10/01 I_E_542 add atart by Shigeto.Niki
          ffvl.attribute9,
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
          ffvl.flex_value_set_id,
          ffvl.creation_date,
          ffvl.last_update_date
        FROM
          fnd_flex_value_sets           ffvs,
          fnd_flex_values               ffvl,
          fnd_flex_values_tl            ffvt,
          fnd_flex_value_norm_hierarchy ffvh
        WHERE
              ffvl.flex_value_set_id    =  ffvs.flex_value_set_id
          AND ffvt.flex_value_id        =  ffvl.flex_value_id
          AND ffvt.language             =  'JA'
          AND ffvl.enabled_flag         =  'Y'
          AND ffvs.flex_value_set_name  =  'XX03_DEPARTMENT'
          AND ffvh.flex_value_set_id    =  ffvl.flex_value_set_id
          AND ffvl.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high
-- 2009/09/02 áQ0001224 modify start by Yutaka.Kuboshima
-- Æ±út -> cÆúÉÏX
--          AND xxccp_common_pkg2.get_process_date BETWEEN
          AND xxccp_common_pkg2.get_working_day(xxccp_common_pkg2.get_process_date
                                               ,1
                                               ,'SALES_CAL') BETWEEN
-- 2009/09/02 áQ0001224 modify end by Yutaka.Kuboshima
                    NVL(ffvl.start_date_active,to_date('19000101','YYYYMMDD'))
                AND NVL(ffvl.end_date_active,to_date('99991231','YYYYMMDD'))
-- 2009/04/20 áQT1_0590 add start by Yutaka.Kuboshima
          AND NOT EXISTS(
                    SELECT
                      'X'
                    FROM 
                      fnd_flex_value_norm_hierarchy ffvh2
                    WHERE 
                          ffvh.parent_flex_value   =  fnd_profile.value('XXCMM1_AFF_DEPT_DUMMY_CD')
                      AND ffvh2.flex_value_set_id  =  ffvl.flex_value_set_id
                        )
-- 2009/04/20 áQT1_0590 add end by Yutaka.Kuboshima
      ) FFV
      START WITH ffv.flex_value = ffv.parent_flex_value
      CONNECT BY PRIOR ffv.flex_value = ffv.parent_flex_value
             AND (ffv.flex_value != ffv.parent_flex_value)
    ) dpt
    WHERE
          dpt.summary_flag = 'N'
  ) dph
) tbl
/
COMMENT ON TABLE apps.xxcmm_hierarchy_dept_v                         IS 'åKwr['
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.cur_dpt_cd             IS 'ÅºwåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.cur_dpt_lv             IS 'ÅºwåKwx'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.cur_dpt_fvl_name       IS 'Åºwåè`¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_cd                IS 'PKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_name              IS 'PKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_abbreviate        IS 'PKwÚåª¼'
/
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_sort_num             IS 'PKwÚÀÑ'
-- /
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_start_date_active IS 'PKwÚKpJnú'
/
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_old_cd            IS 'PKwÚ{R[h'
/
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_new_cd            IS 'PKwÚV{R[h'
/
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt1_div               IS 'PKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_cd                IS 'QKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_name              IS 'QKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_abbreviate        IS 'QKwÚåª¼'
/
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_sort_num             IS 'QKwÚÀÑ'
-- /
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_start_date_active IS 'QKwÚKpJnú'
/
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_old_cd            IS 'QKwÚ{R[h'
/
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_new_cd            IS 'QKwÚV{R[h'
/
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt2_div               IS 'QKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_cd                IS 'RKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_name              IS 'RKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_abbreviate        IS 'RKwÚåª¼'
/
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_sort_num             IS 'RKwÚÀÑ'
-- /
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_start_date_active IS 'RKwÚKpJnú'
/
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_old_cd            IS 'RKwÚ{R[h'
/
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_new_cd            IS 'RKwÚV{R[h'
/
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt3_div               IS 'RKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_cd                IS 'SKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_name              IS 'SKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_abbreviate        IS 'SKwÚåª¼'
/
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_sort_num             IS 'SKwÚÀÑ'
-- /
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_start_date_active IS 'SKwÚKpJnú'
/
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_old_cd            IS 'SKwÚ{R[h'
/
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_new_cd            IS 'SKwÚV{R[h'
/
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt4_div               IS 'SKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_cd                IS 'TKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_name              IS 'TKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_abbreviate        IS 'TKwÚåª¼'
/
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_sort_num             IS 'TKwÚÀÑ'
-- /
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_start_date_active IS 'TKwÚKpJnú'
/
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_old_cd            IS 'TKwÚ{R[h'
/
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_new_cd            IS 'TKwÚV{R[h'
/
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt5_div               IS 'TKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_cd                IS 'UKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_name              IS 'UKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_abbreviate        IS 'UKwÚåª¼'
/
-- 2009/10/01 I_E_542 mod start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_sort_num             IS 'UKwÚÀÑ'
-- /
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_start_date_active IS 'UKwÚKpJnú'
/
-- 2009/10/01 I_E_542 mod end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_old_cd            IS 'UKwÚ{R[h'
/
-- 2009/10/01 I_E_542 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_new_cd            IS 'UKwÚV{R[h'
/
-- 2009/10/01 I_E_542 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.dpt6_div               IS 'UKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.flex_value_set_id      IS 'lZbgID'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.creation_date          IS 'ì¬ú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.last_update_date       IS 'ÅIXVú'
/
-- 2009/10/01 I_E_542 delete start by Shigeto.Niki
-- COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_v.hierarchy_sort_key IS 'åKw\[gL['
-- /
-- 2009/10/01 I_E_542 delete end by Shigeto.Niki
