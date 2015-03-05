/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_TRANSACTION_TYPE_V
 * Description     : �q�ɊǗ��V�X�e������^�C�v�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/10/29    1.0   Y.Umino          �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_transaction_type_v
  (  transaction_type_code                                       -- ����^�C�v�R�[�h
   , transaction_type_name                                       -- ����^�C�v��
  )
AS
  SELECT lookup_code  AS transaction_type_code
       , meaning      AS transaction_type_name
  FROM
  (
  SELECT flvma.lookup_code  AS lookup_code
       , flvma.meaning      AS meaning
  FROM fnd_lookup_values flvma
  WHERE flvma.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
    AND flvma.attribute1 IN 
        (SELECT flvmb.lookup_code
         FROM fnd_lookup_values  flvmb
         WHERE flvmb.lookup_type = 'XXCOI1_TRANSACTION_TYPE_NAME'
           AND flvmb.lookup_code IN ('10','20','70')
           AND flvmb.language = 'JA'
           AND flvmb.enabled_flag = 'Y'
           AND xxccp_common_pkg2.get_process_date BETWEEN flvmb.start_date_active AND NVL( flvmb.end_date_active, xxccp_common_pkg2.get_process_date )
       )
  AND flvma.language = 'JA'
  AND flvma.enabled_flag = 'Y'
  AND xxccp_common_pkg2.get_process_date BETWEEN flvma.start_date_active AND NVL( flvma.end_date_active, xxccp_common_pkg2.get_process_date )
  UNION ALL
  SELECT flvmc.lookup_code  AS lookup_code
       , flvmc.meaning      AS meaning
  FROM fnd_lookup_values flvmc
  WHERE flvmc.lookup_type = 'XXCOI1_TRANSACTION_TYPE_NAME'
    AND flvmc.lookup_code IN ('90','100','110','120','130','140','150','160','170','180','190','200','320','330','340','350','360','370','390','400','410')
    AND flvmc.language = 'JA'
    AND flvmc.enabled_flag = 'Y'
    AND xxccp_common_pkg2.get_process_date BETWEEN flvmc.start_date_active AND NVL( flvmc.end_date_active, xxccp_common_pkg2.get_process_date ) 
  )
  ORDER BY TO_NUMBER(lookup_code)
/
COMMENT ON TABLE xxcoi_transaction_type_v IS '�q�ɊǗ��V�X�e������^�C�v�r���[';
/
COMMENT ON COLUMN xxcoi_transaction_type_v.transaction_type_code IS '����^�C�v�R�[�h';
/
COMMENT ON COLUMN xxcoi_transaction_type_v.transaction_type_name IS '����^�C�v��';
/
