CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_STC_LOV_INFO_SEC_V" (
   "USER_ID"
  ,"WHSE_CODE"
  ,"WHSE_NAME"
  ) AS 
  SELECT
    info_sec.user_id,              -- ���[�U�[ID
    info_sec.whse_code,            -- �q�ɃR�[�h
    info_sec.whse_name             -- �E�v
  FROM(
       SELECT
         fu.user_id,                  -- ���[�U�[ID
         iwm.whse_code,               -- �q�ɃR�[�h
         iwm.whse_name                -- �E�v
       FROM
         fnd_user                  fu,   -- ���[�U�[�}�X�^
         per_all_people_f          papf, -- �]�ƈ������}�X�^
         mtl_item_locations        mil,  -- OPM�ۊǏꏊ�}�X�^
         hr_all_organization_units haou, -- �݌ɑg�D�}�X�^
         ic_whse_mst               iwm   -- OPM�q�Ƀ}�X�^
       WHERE fu.employee_id           = papf.person_id
       AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                AND TRUNC(papf.effective_end_date)
       AND   papf.attribute4          = mil.attribute13
       AND   papf.attribute3          = '2'
       AND   haou.organization_id     = mil.organization_id
       AND   iwm.mtl_organization_id  = haou.organization_id
       AND   haou.date_from          <=  TRUNC(SYSDATE)
       AND ( haou.date_to            IS NULL
         OR  haou.date_to            >= TRUNC(SYSDATE) )
       AND   mil.disable_date        IS NULL
       UNION
       SELECT
         fu.user_id,                  -- ���[�U�[ID
         iwm.whse_code,               -- �q�ɃR�[�h
         iwm.whse_name                -- �E�v
       FROM
         fnd_user                  fu,   -- ���[�U�[�}�X�^
         per_all_people_f          papf, -- �]�ƈ������}�X�^
         mtl_item_locations        mil,  -- OPM�ۊǏꏊ�}�X�^
         mtl_item_locations        mil2, -- OPM�ۊǏꏊ�}�X�^
         hr_all_organization_units haou, -- �݌ɑg�D�}�X�^
         ic_whse_mst               iwm   -- OPM�q�Ƀ}�X�^
       WHERE fu.employee_id           = papf.person_id
       AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                AND TRUNC(papf.effective_end_date)
       AND   papf.attribute4          = mil.attribute13
       AND   papf.attribute3          = '2'
       AND   mil.segment1             = mil2.attribute8
       AND   haou.organization_id     = mil2.organization_id
       AND   iwm.mtl_organization_id  = haou.organization_id
       AND   haou.date_from          <= TRUNC(SYSDATE)
       AND ( haou.date_to            IS NULL
         OR  haou.date_to            >= TRUNC(SYSDATE) )
       AND   mil.disable_date        IS NULL
       AND   mil2.disable_date       IS NULL
       UNION
       SELECT
         fu.user_id,                  -- ���[�U�[ID
         iwm.whse_code,               -- �q�ɃR�[�h
         iwm.whse_name                -- �E�v
       FROM
         fnd_user                  fu,   -- ���[�U�[�}�X�^
         per_all_people_f          papf, -- �]�ƈ������}�X�^
         mtl_item_locations        mil,  -- OPM�ۊǏꏊ�}�X�^
         hr_all_organization_units haou, -- �݌ɑg�D�}�X�^
         ic_whse_mst               iwm   -- OPM�q�Ƀ}�X�^
       WHERE fu.employee_id           = papf.person_id
       AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                AND TRUNC(papf.effective_end_date)
       AND   papf.attribute3          = '1'
       AND   haou.organization_id     = mil.organization_id
       AND   iwm.mtl_organization_id  = haou.organization_id
       AND   haou.date_from          <= TRUNC(SYSDATE)
       AND ( haou.date_to            IS NULL
         OR  haou.date_to            >= TRUNC(SYSDATE) )
       AND   mil.disable_date        IS NULL
       ) INFO_SEC
  GROUP BY info_sec.user_id,
           info_sec.whse_code,
           info_sec.whse_name
  ;
--
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.USER_ID  IS '���[�U�[ID';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_CODE  IS '�q�ɃR�[�h';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_NAME  IS '�q�ɖ�';
--
COMMENT ON TABLE  XXINV_STC_LOV_INFO_SEC_V IS '�݌�_�l�Z�b�g�pVIEW_���Z�L�����e�B' ;

/