CREATE OR REPLACE FORCE VIEW apps.xxcmm_hierarchy_dept_all_v
(
  cur_dpt_cd,
  cur_dpt_lv,
  cur_dpt_fvl_name,
  dpt1_cd,
  dpt1_name,
  dpt1_abbreviate,
  dpt1_sort_num,
  dpt1_old_cd,
  dpt1_div,
  dpt2_cd,
  dpt2_name,
  dpt2_abbreviate,
  dpt2_sort_num,
  dpt2_old_cd,
  dpt2_div,
  dpt3_cd,
  dpt3_name,
  dpt3_abbreviate,
  dpt3_sort_num,
  dpt3_old_cd,
  dpt3_div,
  dpt4_cd,
  dpt4_name,
  dpt4_abbreviate,
  dpt4_sort_num,
  dpt4_old_cd,
  dpt4_div,
  dpt5_cd,
  dpt5_name,
  dpt5_abbreviate,
  dpt5_sort_num,
  dpt5_old_cd,
  dpt5_div,
  dpt6_cd,
  dpt6_name,
  dpt6_abbreviate,
  dpt6_sort_num,
  dpt6_old_cd,
  dpt6_div,
  enabled_flag,
  start_date_active,
  end_date_active,
  flex_value_set_id,
  creation_date,
  last_update_date,
  hierarchy_sort_key
) AS 
SELECT
  tbl.cur_dpt_cd,
  tbl.cur_dpt_lv,
  tbl.cur_dpt_fvl_name,
  tbl.dpt1_cd,
  tbl.dpt1_name,
  tbl.dpt1_abbreviate,
  tbl.dpt1_sort_num,
  tbl.dpt1_old_cd,
  tbl.dpt1_div,
  tbl.dpt2_cd,
  tbl.dpt2_name,
  tbl.dpt2_abbreviate,
  tbl.dpt2_sort_num,
  tbl.dpt2_old_cd,
  tbl.dpt2_div,
  tbl.dpt3_cd,
  tbl.dpt3_name,
  tbl.dpt3_abbreviate,
  tbl.dpt3_sort_num,
  tbl.dpt3_old_cd,
  tbl.dpt3_div,
  tbl.dpt4_cd,
  tbl.dpt4_name,
  tbl.dpt4_abbreviate,
  tbl.dpt4_sort_num,
  tbl.dpt4_old_cd,
  tbl.dpt4_div,
  tbl.dpt5_cd,
  tbl.dpt5_name,
  tbl.dpt5_abbreviate,
  tbl.dpt5_sort_num,
  tbl.dpt5_old_cd,
  tbl.dpt5_div,
  tbl.dpt6_cd,
  tbl.dpt6_name,
  tbl.dpt6_abbreviate,
  tbl.dpt6_sort_num,
  tbl.dpt6_old_cd,
  tbl.dpt6_div,
  tbl.enabled_flag,
  tbl.start_date_active,
  tbl.end_date_active,
  tbl.flex_value_set_id,
  tbl.creation_date,
  tbl.last_update_date,
  ( '01' ||
    LPAD(NVL(tbl.dpt1_sort_num,'999'),3,'0') ||
    LPAD(tbl.dpt1_cd,4,'0') || 
    '02' ||
    LPAD(NVL(tbl.dpt2_sort_num,'999'),3,'0') ||
    LPAD(tbl.dpt2_cd,4,'0') || 
    '03' ||
    LPAD(NVL(tbl.dpt3_sort_num,'999'),3,'0') ||
    LPAD(tbl.dpt3_cd,4,'0') || 
    '04' ||
    LPAD(NVL(tbl.dpt4_sort_num,'999'),3,'0') ||
    LPAD(tbl.dpt4_cd,4,'0') || 
    '05' ||
    LPAD(NVL(tbl.dpt5_sort_num,'999'),3,'0') ||
    LPAD(tbl.dpt5_cd,4,'0') || 
    '06' ||
    LPAD(NVL(tbl.dpt6_sort_num,'999'),3,'0') ||
    LPAD(tbl.dpt6_cd,4,'0')
  ) AS  hierarchy_sort_key
FROM
(
  SELECT
    dph.fvl_cd                        AS  cur_dpt_cd,
    dph.fvl_level                     AS  cur_dpt_lv,
    dph.fvl_name                      AS  cur_dpt_fvl_name,
    /* �P�K�w�� */
    dph.dpt1_cd,
    dph.dpt1_name,
    dph.dpt1_abbreviate,
    dph.dpt1_sort_num,
    dph.dpt1_old_cd,
    dph.dpt1_div,
    /* �Q�K�w�� */
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
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_sort_num
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_sort_num
      ELSE
        dph.dpt1_sort_num
      END
    END                               AS  dpt2_sort_num,
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_old_cd
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_old_cd
      ELSE
        dph.dpt1_old_cd
      END
    END                               AS  dpt2_old_cd,
    CASE WHEN dph.dpt2_cd IS NULL THEN
      dph.dpt1_div
    ELSE
      CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
        dph.dpt2_div
      ELSE
        dph.dpt1_div
      END
    END                               AS  dpt2_div,
    /* �R�K�w�� */
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
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_sort_num
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_sort_num
      ELSE
        dph.dpt2_sort_num
      END
    END                               AS  dpt3_sort_num,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_old_cd
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_old_cd
      ELSE
        dph.dpt2_old_cd
      END
    END                               AS  dpt3_old_cd,
    CASE WHEN dph.dpt3_cd IS NULL THEN
      dph.dpt1_div
    ELSE
      CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
        dph.dpt3_div
      ELSE
        dph.dpt2_div
      END
    END                               AS  dpt3_div,
    /* �S�K�w�� */
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
    CASE WHEN dph.dpt4_cd IS NULL THEN
      CASE WHEN dph.dpt2_cd IS NULL THEN
        dph.dpt1_sort_num
      ELSE
        CASE WHEN dph.dpt2_cd <> dph.fvl_cd THEN
          dph.dpt2_sort_num
        ELSE
          dph.dpt1_sort_num
        END
      END
    ELSE
      CASE WHEN dph.dpt4_cd <> dph.fvl_cd THEN
        dph.dpt4_sort_num
      ELSE
        dph.dpt3_sort_num
      END
    END                               AS  dpt4_sort_num,
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
    /* �T�K�w�� */
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
    CASE WHEN dph.dpt5_cd IS NULL THEN
      CASE WHEN dph.dpt3_cd IS NULL THEN
        dph.dpt1_sort_num
      ELSE
        CASE WHEN dph.dpt3_cd <> dph.fvl_cd THEN
          dph.dpt3_sort_num
        ELSE
          dph.dpt2_sort_num
        END
      END
    ELSE
      CASE WHEN dph.dpt5_cd <> dph.fvl_cd THEN
        dph.dpt5_sort_num
      ELSE
        dph.dpt4_sort_num
      END
    END                               AS  dpt5_sort_num,
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
    /* �U�K�w�� */
    NVL(dph.dpt6_cd,dph.fvl_cd)             AS  dpt6_cd,
    NVL(dph.dpt6_name,dph.attribute4)       AS  dpt6_name,
    NVL(dph.dpt6_abbreviate,dph.attribute5) AS  dpt6_abbreviate,
    NVL(dph.dpt6_sort_num,dph.attribute6)   AS  dpt6_sort_num,
    NVL(dph.dpt6_old_cd,dph.attribute7)     AS  dpt6_old_cd,
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
      dpt.dpt_lelel         AS  fvl_level,
      /* �P�K�w�� */
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
        dpt.dpt_sort_num_root,
        INSTR(dpt.dpt_sort_num_root,'\',1,1)+1,
        INSTR(dpt.dpt_sort_num_root,'\',1,2)-INSTR(dpt.dpt_sort_num_root,'\',1,1)-1
      )                     AS  dpt1_sort_num,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,1)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,2)-INSTR(dpt.dpt_old_cd_root,'\',1,1)-1
      )                     AS  dpt1_old_cd,
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,1)+1,
        INSTR(dpt.dpt_div_root,'\',1,2)-INSTR(dpt.dpt_div_root,'\',1,1)-1
      )                     AS  dpt1_div,
      /* �Q�K�w�� */
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
        dpt.dpt_sort_num_root,
        INSTR(dpt.dpt_sort_num_root,'\',1,2)+1,
        INSTR(dpt.dpt_sort_num_root,'\',1,3)-INSTR(dpt.dpt_sort_num_root,'\',1,2)-1
      )                     AS  dpt2_sort_num,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,2)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,3)-INSTR(dpt.dpt_old_cd_root,'\',1,2)-1
      )                     AS  dpt2_old_cd,
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,2)+1,
        INSTR(dpt.dpt_div_root,'\',1,3)-INSTR(dpt.dpt_div_root,'\',1,2)-1
      )                     AS  dpt2_div,
      /* �R�K�w�� */
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
        dpt.dpt_sort_num_root,
        INSTR(dpt.dpt_sort_num_root,'\',1,3)+1,
        INSTR(dpt.dpt_sort_num_root,'\',1,4)-INSTR(dpt.dpt_sort_num_root,'\',1,3)-1
      )                     AS  dpt3_sort_num,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,3)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,4)-INSTR(dpt.dpt_old_cd_root,'\',1,3)-1
      )                     AS  dpt3_old_cd,
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,3)+1,
        INSTR(dpt.dpt_div_root,'\',1,4)-INSTR(dpt.dpt_div_root,'\',1,3)-1
      )                     AS  dpt3_div,
      /* �S�K�w�� */
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
        dpt.dpt_sort_num_root,
        INSTR(dpt.dpt_sort_num_root,'\',1,4)+1,
        INSTR(dpt.dpt_sort_num_root,'\',1,5)-INSTR(dpt.dpt_sort_num_root,'\',1,4)-1
      )                     AS  dpt4_sort_num,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,4)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,5)-INSTR(dpt.dpt_old_cd_root,'\',1,4)-1
      )                     AS  dpt4_old_cd,
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,4)+1,
        INSTR(dpt.dpt_div_root,'\',1,5)-INSTR(dpt.dpt_div_root,'\',1,4)-1
      )                     AS  dpt4_div,
      /* �T�K�w�� */
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
        dpt.dpt_sort_num_root,
        INSTR(dpt.dpt_sort_num_root,'\',1,5)+1,
        INSTR(dpt.dpt_sort_num_root,'\',1,6)-INSTR(dpt.dpt_sort_num_root,'\',1,5)-1
      )                     AS  dpt5_sort_num,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,5)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,6)-INSTR(dpt.dpt_old_cd_root,'\',1,5)-1
      )                     AS  dpt5_old_cd,
      SUBSTR(
        dpt.dpt_div_root,
        INSTR(dpt.dpt_div_root,'\',1,5)+1,
        INSTR(dpt.dpt_div_root,'\',1,6)-INSTR(dpt.dpt_div_root,'\',1,5)-1
      )                     AS  dpt5_div,
      /* �U�K�w�� */
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
        dpt.dpt_sort_num_root,
        INSTR(dpt.dpt_sort_num_root,'\',1,6)+1,
        INSTR(dpt.dpt_sort_num_root,'\',1,7)-INSTR(dpt.dpt_sort_num_root,'\',1,6)-1
      )                     AS  dpt6_sort_num,
      SUBSTR(
        dpt.dpt_old_cd_root,
        INSTR(dpt.dpt_old_cd_root,'\',1,6)+1,
        INSTR(dpt.dpt_old_cd_root,'\',1,7)-INSTR(dpt.dpt_old_cd_root,'\',1,6)-1
      )                     AS  dpt6_old_cd,
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
        ffv.summary_flag,
        ffv.parent_flex_value,
        LEVEL AS dpt_lelel,
        SYS_CONNECT_BY_PATH(ffv.flex_value, '\') || '\' AS dpt_cd_root,
        SYS_CONNECT_BY_PATH(ffv.description,'\') || '\' AS fvl_name_root,
        SYS_CONNECT_BY_PATH(ffv.attribute4,'\')  || '\' AS dpt_name_root,
        SYS_CONNECT_BY_PATH(ffv.attribute5,'\')  || '\' AS dpt_abbreviate_root,
        SYS_CONNECT_BY_PATH(ffv.attribute6,'\')  || '\' AS dpt_sort_num_root,
        SYS_CONNECT_BY_PATH(ffv.attribute7,'\')  || '\' AS dpt_old_cd_root,
        SYS_CONNECT_BY_PATH(ffv.attribute8,'\')  || '\' AS dpt_div_root,
        ffv.enabled_flag,
        ffv.start_date_active,
        ffv.end_date_active,
        ffv.flex_value_set_id,
        ffv.creation_date,
        ffv.last_update_date
      FROM
      (
        /* �ŏ�ʕ���擾 */
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
-- 2009/04/20 ��QT1_0590 add start by Yutaka.Kuboshima
          AND ffvl.flex_value          <>  fnd_profile.value('XXCMM1_AFF_DEPT_DUMMY_CD')
-- 2009/04/20 ��QT1_0590 add end by Yutaka.Kuboshima
          AND NOT EXISTS(
                SELECT
                  'X'
                FROM
                  fnd_flex_value_norm_hierarchy ffvh
                WHERE
                      ffvh.flex_value_set_id =  ffvl.flex_value_set_id
                  AND ffvl.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high
-- 2009/04/20 ��QT1_0590 add start by Yutaka.Kuboshima
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
-- 2009/04/20 ��QT1_0590 add end by Yutaka.Kuboshima
        /* ���w����擾 */
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
-- 2009/04/20 ��QT1_0590 add start by Yutaka.Kuboshima
          AND NOT EXISTS(
                    SELECT
                      'X'
                    FROM 
                      fnd_flex_value_norm_hierarchy ffvh2
                    WHERE 
                          ffvh.parent_flex_value   =  fnd_profile.value('XXCMM1_AFF_DEPT_DUMMY_CD')
                      AND ffvh2.flex_value_set_id  =  ffvl.flex_value_set_id
                        )
-- 2009/04/20 ��QT1_0590 add end by Yutaka.Kuboshima
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
COMMENT ON TABLE apps.xxcmm_hierarchy_dept_all_v                        IS '�S����K�w�r���['
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.cur_dpt_cd            IS '�ŉ��w����R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.cur_dpt_lv            IS '�ŉ��w����K�w���x��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.cur_dpt_fvl_name      IS '�ŉ��w�����`��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt1_cd               IS '�P�K�w�ڕ���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt1_name             IS '�P�K�w�ڕ��吳����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt1_abbreviate       IS '�P�K�w�ڕ��嗪��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt1_sort_num         IS '�P�K�w�ڕ��я�'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt1_old_cd           IS '�P�K�w�ڋ��{���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt1_div              IS '�P�K�w�ڕ���敪'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt2_cd               IS '�Q�K�w�ڕ���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt2_name             IS '�Q�K�w�ڕ��吳����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt2_abbreviate       IS '�Q�K�w�ڕ��嗪��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt2_sort_num         IS '�Q�K�w�ڕ��я�'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt2_old_cd           IS '�Q�K�w�ڋ��{���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt2_div              IS '�Q�K�w�ڕ���敪'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt3_cd               IS '�R�K�w�ڕ���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt3_name             IS '�R�K�w�ڕ��吳����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt3_abbreviate       IS '�R�K�w�ڕ��嗪��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt3_sort_num         IS '�R�K�w�ڕ��я�'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt3_old_cd           IS '�R�K�w�ڋ��{���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt3_div              IS '�R�K�w�ڕ���敪'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt4_cd               IS '�S�K�w�ڕ���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt4_name             IS '�S�K�w�ڕ��吳����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt4_abbreviate       IS '�S�K�w�ڕ��嗪��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt4_sort_num         IS '�S�K�w�ڕ��я�'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt4_old_cd           IS '�S�K�w�ڋ��{���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt4_div              IS '�S�K�w�ڕ���敪'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt5_cd               IS '�T�K�w�ڕ���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt5_name             IS '�T�K�w�ڕ��吳����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt5_abbreviate       IS '�T�K�w�ڕ��嗪��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt5_sort_num         IS '�T�K�w�ڕ��я�'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt5_old_cd           IS '�T�K�w�ڋ��{���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt5_div              IS '�T�K�w�ڕ���敪'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt6_cd               IS '�U�K�w�ڕ���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt6_name             IS '�U�K�w�ڕ��吳����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt6_abbreviate       IS '�U�K�w�ڕ��嗪��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt6_sort_num         IS '�U�K�w�ڕ��я�'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt6_old_cd           IS '�U�K�w�ڋ��{���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.dpt6_div              IS '�U�K�w�ڕ���敪'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.enabled_flag          IS '�g�p�\�t���O'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.start_date_active     IS '�L�����ԊJ�n��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.end_date_active       IS '�L�����ԏI����'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.flex_value_set_id     IS '�l�Z�b�gID'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.creation_date         IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.last_update_date      IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcmm_hierarchy_dept_all_v.hierarchy_sort_key    IS '����K�w�\�[�g�L�['
/
