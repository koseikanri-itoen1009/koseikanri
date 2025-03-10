/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcmm_hierarchy_dept_all2_v
 * Description     : SåKwr[Q(ºÊKwâ®p)
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/12/15    1.0   Y.Kuboshima      VKì¬
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW apps.xxcmm_hierarchy_dept_all2_v
(
  cur_dpt_cd,
  cur_dpt_lv,
  cur_dpt_fvl_name,
  dpt1_cd,
  dpt1_name,
  dpt1_abbreviate,
  dpt1_start_date_active,
  dpt1_old_cd,
  dpt1_new_cd,
  dpt1_div,
  dpt2_cd,
  dpt2_name,
  dpt2_abbreviate,
  dpt2_start_date_active,
  dpt2_old_cd,
  dpt2_new_cd,
  dpt2_div,
  dpt3_cd,
  dpt3_name,
  dpt3_abbreviate,
  dpt3_start_date_active,
  dpt3_old_cd,
  dpt3_new_cd,
  dpt3_div,
  dpt4_cd,
  dpt4_name,
  dpt4_abbreviate,
  dpt4_start_date_active,
  dpt4_old_cd,
  dpt4_new_cd,
  dpt4_div,
  dpt5_cd,
  dpt5_name,
  dpt5_abbreviate,
  dpt5_start_date_active,
  dpt5_old_cd,
  dpt5_new_cd,
  dpt5_div,
  dpt6_cd,
  dpt6_name,
  dpt6_abbreviate,
  dpt6_start_date_active,
  dpt6_old_cd,
  dpt6_new_cd,
  dpt6_div,
  enabled_flag,
  start_date_active,
  end_date_active,
  flex_value_set_id,
  creation_date,
  last_update_date
) AS 
SELECT
  tbl.cur_dpt_cd,
  tbl.cur_dpt_lv,
  tbl.cur_dpt_fvl_name,
  tbl.dpt1_cd,
  tbl.dpt1_name,
  tbl.dpt1_abbreviate,
  tbl.dpt1_start_date_active,
  tbl.dpt1_old_cd,
  tbl.dpt1_new_cd,
  tbl.dpt1_div,
  tbl.dpt2_cd,
  tbl.dpt2_name,
  tbl.dpt2_abbreviate,
  tbl.dpt2_start_date_active,
  tbl.dpt2_old_cd,
  tbl.dpt2_new_cd,
  tbl.dpt2_div,
  tbl.dpt3_cd,
  tbl.dpt3_name,
  tbl.dpt3_abbreviate,
  tbl.dpt3_start_date_active,
  tbl.dpt3_old_cd,
  tbl.dpt3_new_cd,
  tbl.dpt3_div,
  tbl.dpt4_cd,
  tbl.dpt4_name,
  tbl.dpt4_abbreviate,
  tbl.dpt4_start_date_active,
  tbl.dpt4_old_cd,
  tbl.dpt4_new_cd,
  tbl.dpt4_div,
  tbl.dpt5_cd,
  tbl.dpt5_name,
  tbl.dpt5_abbreviate,
  tbl.dpt5_start_date_active,
  tbl.dpt5_old_cd,
  tbl.dpt5_new_cd,
  tbl.dpt5_div,
  tbl.dpt6_cd,
  tbl.dpt6_name,
  tbl.dpt6_abbreviate,
  tbl.dpt6_start_date_active,
  tbl.dpt6_old_cd,
  tbl.dpt6_new_cd,
  tbl.dpt6_div,
  tbl.enabled_flag,
  tbl.start_date_active,
  tbl.end_date_active,
  tbl.flex_value_set_id,
  tbl.creation_date,
  tbl.last_update_date
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
    dph.dpt1_start_date_active,
    dph.dpt1_old_cd,
    dph.dpt1_new_cd,
    dph.dpt1_div,
    /* QKwÚ */
    dph.dpt2_cd,
    dph.dpt2_name,
    dph.dpt2_abbreviate,
    dph.dpt2_start_date_active,
    dph.dpt2_old_cd,
    dph.dpt2_new_cd,
    dph.dpt2_div,
    /* RKwÚ */
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_cd
    ELSE
      dph.dpt3_cd
    END                               AS  dpt3_cd,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_name
    ELSE
      dph.dpt3_name
    END                               AS  dpt3_name,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_abbreviate
    ELSE
      dph.dpt3_abbreviate
    END                               AS  dpt3_abbreviate,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_start_date_active
    ELSE
      dph.dpt3_start_date_active
    END                               AS  dpt3_start_date_active,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_old_cd
    ELSE
      dph.dpt3_old_cd
    END                               AS  dpt3_old_cd,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_new_cd
    ELSE
      dph.dpt3_new_cd
    END                               AS  dpt3_new_cd,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt2_div
    ELSE
      dph.dpt3_div
    END                               AS  dpt3_div,
    /* SKwÚ */
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_cd
      ELSE
        dph.dpt3_cd
      END
    ELSE
      dph.dpt4_cd
    END                               AS  dpt4_cd,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_name
      ELSE
        dph.dpt3_name
      END
    ELSE
      dph.dpt4_name
    END                               AS  dpt4_name,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_abbreviate
      ELSE
        dph.dpt3_abbreviate
      END
    ELSE
      dph.dpt4_abbreviate
    END                               AS  dpt4_abbreviate,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_start_date_active
      ELSE
        dph.dpt3_start_date_active
      END
    ELSE
      dph.dpt4_start_date_active
    END                               AS  dpt4_start_date_active,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_old_cd
      ELSE
        dph.dpt3_old_cd
      END
    ELSE
      dph.dpt4_old_cd
    END                               AS  dpt4_old_cd,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_new_cd
      ELSE
        dph.dpt3_new_cd
      END
    ELSE
      dph.dpt4_new_cd
    END                               AS  dpt4_new_cd,
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_div
      ELSE
        dph.dpt3_div
      END
    ELSE
      dph.dpt4_div
    END                               AS  dpt4_div,
    /* TKwÚ */
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_cd
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_cd
        ELSE
          dph.dpt3_cd
        END
      END
    ELSE
      dph.dpt5_cd
    END                               AS  DPT5_CD,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_name
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_name
        ELSE
          dph.dpt3_name
        END
      END
    ELSE
      dph.dpt5_name
    END                               AS  dpt5_name,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_abbreviate
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_abbreviate
        ELSE
          dph.dpt3_abbreviate
        END
      END
    ELSE
      dph.dpt5_abbreviate
    END                               AS  dpt5_abbreviate,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_start_date_active
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_start_date_active
        ELSE
          dph.dpt3_start_date_active
        END
      END
    ELSE
      dph.dpt5_start_date_active
    END                               AS  dpt5_start_date_active,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_old_cd
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_old_cd
        ELSE
          dph.dpt3_old_cd
        END
      END
    ELSE
      dph.dpt5_old_cd
    END                               AS  dpt5_old_cd,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_new_cd
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_new_cd
        ELSE
          dph.dpt3_new_cd
        END
      END
    ELSE
      dph.dpt5_new_cd
    END                               AS  dpt5_new_cd,
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt2_div
      ELSE
        CASE when dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt4_div
        ELSE
          dph.dpt3_div
        END
      END
    ELSE
      dph.dpt5_div
    END                               AS  dpt5_div,
    /* UKwÚ */
    NVL(dph.dpt6_cd,dph.fvl_cd)             AS  dpt6_cd,
    NVL(dph.dpt6_name,dph.attribute4)       AS  dpt6_name,
    NVL(dph.dpt6_abbreviate,dph.attribute5) AS  dpt6_abbreviate,
    NVL(dph.dpt6_start_date_active,dph.attribute6)   AS  dpt6_start_date_active,
    NVL(dph.dpt6_old_cd,dph.attribute7)     AS  dpt6_old_cd,
    NVL(dph.dpt6_new_cd,dph.attribute9)     AS  dpt6_new_cd,
    NVL(dph.dpt6_div,dph.attribute8)        AS  dpt6_div,
    dph.enabled_flag,
    dph.start_date_active,
    dph.end_date_active,
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
      dpt.attribute9        AS  attribute9,
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
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,1)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,2)-INSTR(dpt.dpt_start_date_active_root,'\',1,1)-1
      )                     AS  dpt1_start_date_active,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,1)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,2)-INSTR(dpt.dpt_old_cd_root,'\',1,1)-1
      )                     AS  dpt1_old_cd,
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,1)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,2)-INSTR(dpt.dpt_new_cd_root,'\',1,1)-1
      )                     AS  dpt1_new_cd,
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
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,2)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,3)-INSTR(dpt.dpt_start_date_active_root,'\',1,2)-1
      )                     AS  dpt2_start_date_active,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,2)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,3)-INSTR(dpt.dpt_old_cd_root,'\',1,2)-1
      )                     AS  dpt2_old_cd,
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,2)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,3)-INSTR(dpt.dpt_new_cd_root,'\',1,2)-1
      )                     AS  dpt2_new_cd,
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
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,3)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,4)-INSTR(dpt.dpt_start_date_active_root,'\',1,3)-1
      )                     AS  dpt3_start_date_active,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,3)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,4)-INSTR(dpt.dpt_old_cd_root,'\',1,3)-1
      )                     AS  dpt3_old_cd,
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,3)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,4)-INSTR(dpt.dpt_new_cd_root,'\',1,3)-1
      )                     AS  dpt3_new_cd,
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
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,4)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,5)-INSTR(dpt.dpt_start_date_active_root,'\',1,4)-1
      )                     AS  dpt4_start_date_active,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,4)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,5)-INSTR(dpt.dpt_old_cd_root,'\',1,4)-1
      )                     AS  dpt4_old_cd,
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,4)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,5)-INSTR(dpt.dpt_new_cd_root,'\',1,4)-1
      )                     AS  dpt4_new_cd,
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
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,5)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,6)-INSTR(dpt.dpt_start_date_active_root,'\',1,5)-1
      )                     AS  dpt5_start_date_active,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,5)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,6)-INSTR(dpt.dpt_old_cd_root,'\',1,5)-1
      )                     AS  dpt5_old_cd,
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,5)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,6)-INSTR(dpt.dpt_new_cd_root,'\',1,5)-1
      )                     AS  dpt5_new_cd,
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
      SUBSTR(
        dpt.dpt_start_date_active_root,
        INSTR(dpt.dpt_start_date_active_root,'\',1,6)+1,
        INSTR(dpt.dpt_start_date_active_root,'\',1,7)-INSTR(dpt.dpt_start_date_active_root,'\',1,6)-1
      )                     AS  dpt6_start_date_active,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,6)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,7)-INSTR(dpt.dpt_old_cd_root,'\',1,6)-1
      )                     AS  dpt6_old_cd,
      SUBSTR(
        dpt.dpt_new_cd_root,
        INSTR(dpt.dpt_new_cd_root,'\',1,6)+1,
        INSTR(dpt.dpt_new_cd_root,'\',1,7)-INSTR(dpt.dpt_new_cd_root,'\',1,6)-1
      )                     AS  dpt6_new_cd,
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,6)+1,
        INSTR(dpt.dpt_div_root,'\',1,7)-INSTR(dpt.dpt_div_root,'\',1,6)-1
      )                     AS  dpt6_div,
      dpt.enabled_flag,
      dpt.start_date_active,
      dpt.end_date_active,
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
        ffv.attribute9,
        ffv.summary_flag,
        ffv.parent_flex_value,
        LEVEL AS dpt_lelel,
        SYS_CONNECT_BY_PATH(ffv.flex_value, '\') || '\' AS dpt_cd_root,
        SYS_CONNECT_BY_PATH(ffv.description,'\') || '\' AS fvl_name_root,
        SYS_CONNECT_BY_PATH(ffv.attribute4,'\')  || '\' AS dpt_name_root,
        SYS_CONNECT_BY_PATH(ffv.attribute5,'\')  || '\' AS dpt_abbreviate_root,
        SYS_CONNECT_BY_PATH(ffv.attribute6,'\')  || '\' AS dpt_start_date_active_root,
        SYS_CONNECT_BY_PATH(ffv.attribute7,'\')  || '\' AS dpt_old_cd_root,
        SYS_CONNECT_BY_PATH(ffv.attribute9,'\')  || '\' AS dpt_new_cd_root,
        SYS_CONNECT_BY_PATH(ffv.attribute8,'\')  || '\' AS dpt_div_root,
        ffv.enabled_flag,
        ffv.start_date_active,
        ffv.end_date_active,
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
          ffvl.attribute9,
          ffvl.enabled_flag,
          ffvl.start_date_active,
          ffvl.end_date_active,
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
          AND ffvl.summary_flag         =  'Y'
          AND ffvs.flex_value_set_name  =  'XX03_DEPARTMENT'
          AND ffvl.flex_value          <>  fnd_profile.value('XXCMM1_AFF_DEPT_DUMMY_CD')
          AND NOT EXISTS(
                SELECT
                  'X'
                FROM
                  fnd_flex_value_norm_hierarchy ffvh
                WHERE
                      ffvh.flex_value_set_id =  ffvl.flex_value_set_id
                  AND ffvl.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high
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
          ffvl.attribute9,
          ffvl.enabled_flag,
          ffvl.start_date_active,
          ffvl.end_date_active,
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
          AND ffvs.flex_value_set_name  =  'XX03_DEPARTMENT'
          AND ffvh.flex_value_set_id    =  ffvl.flex_value_set_id
          AND ffvl.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high
          AND NOT EXISTS(
                    SELECT
                      'X'
                    FROM 
                      fnd_flex_value_norm_hierarchy ffvh2
                    WHERE 
                          ffvh.parent_flex_value   =  fnd_profile.value('XXCMM1_AFF_DEPT_DUMMY_CD')
                      AND ffvh2.flex_value_set_id  =  ffvl.flex_value_set_id
                        )
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
COMMENT ON TABLE apps.xxcmm_hierarchy_dept_all2_v                         IS 'SåKwr[Q(ºÊKwâ®p)'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.cur_dpt_cd             IS 'ÅºwåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.cur_dpt_lv             IS 'ÅºwåKwx'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.cur_dpt_fvl_name       IS 'Åºwåè`¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_cd                IS 'PKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_name              IS 'PKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_abbreviate        IS 'PKwÚåª¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_start_date_active IS 'PKwÚKpJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_old_cd            IS 'PKwÚ{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_new_cd            IS 'PKwÚV{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt1_div               IS 'PKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_cd                IS 'QKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_name              IS 'QKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_abbreviate        IS 'QKwÚåª¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_start_date_active IS 'QKwÚKpJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_old_cd            IS 'QKwÚ{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_new_cd            IS 'QKwÚV{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt2_div               IS 'QKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_cd                IS 'RKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_name              IS 'RKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_abbreviate        IS 'RKwÚåª¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_start_date_active IS 'RKwÚKpJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_old_cd            IS 'RKwÚ{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_new_cd            IS 'RKwÚV{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt3_div               IS 'RKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_cd                IS 'SKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_name              IS 'SKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_abbreviate        IS 'SKwÚåª¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_start_date_active IS 'SKwÚKpJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_old_cd            IS 'SKwÚ{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_new_cd            IS 'SKwÚV{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt4_div               IS 'SKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_cd                IS 'TKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_name              IS 'TKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_abbreviate        IS 'TKwÚåª¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_start_date_active IS 'TKwÚKpJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_old_cd            IS 'TKwÚ{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_new_cd            IS 'TKwÚV{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt5_div               IS 'TKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_cd                IS 'UKwÚåR[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_name              IS 'UKwÚå³®¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_abbreviate        IS 'UKwÚåª¼'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_start_date_active IS 'UKwÚKpJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_old_cd            IS 'UKwÚ{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_new_cd            IS 'UKwÚV{R[h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.dpt6_div               IS 'UKwÚåæª'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.enabled_flag           IS 'gpÂ\tO'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.start_date_active      IS 'LøúÔJnú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.end_date_active        IS 'LøúÔI¹ú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.flex_value_set_id      IS 'lZbgID'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.creation_date          IS 'ì¬ú'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all2_v.last_update_date       IS 'ÅIXVú'
/
