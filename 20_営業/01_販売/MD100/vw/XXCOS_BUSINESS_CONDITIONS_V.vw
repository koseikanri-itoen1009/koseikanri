/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_business_conditions_v
 * Description     : �Ƒԕ��ރr���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/20    1.0   T.Nakabayashi   �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_business_conditions_v
AS
SELECT
        flvd.lookup_code                          AS  d_lookup_code,
        flvd.meaning                              AS  d_meaning,
        NVL(flvd.start_date_active, TO_DATE('19000101', 'yyyymmdd'))
                                                  AS  d_start_date_active,
        NVL(flvd.end_date_active,   TO_DATE('99991231', 'yyyymmdd'))
                                                  AS  d_end_date_active,
        flvc.lookup_code                          AS  c_lookup_code,
        flvc.meaning                              AS  c_meaning,
        NVL(flvc.start_date_active, TO_DATE('19000101', 'yyyymmdd'))
                                                  AS  c_start_date_active,
        NVL(flvc.end_date_active,   TO_DATE('99991231', 'yyyymmdd'))
                                                  AS  c_end_date_active,
        flvs.lookup_code                          AS  s_lookup_code,
        flvs.meaning                              AS  s_meaning,
        NVL(flvs.start_date_active, TO_DATE('19000101', 'yyyymmdd'))
                                                  AS  s_start_date_active,
        NVL(flvs.end_date_active,   TO_DATE('99991231', 'yyyymmdd'))
                                                  AS  s_end_date_active
FROM    fnd_lookup_values     flvd,
        fnd_lookup_values     flvc,
        fnd_lookup_values     flvs
WHERE   flvs.lookup_type      =     'XXCMM_CUST_GYOTAI_SHO'
AND     flvs.enabled_flag     =     'Y'
AND     flvs.language         =     SYS_CONTEXT ('USERENV', 'LANG')
AND     flvs.source_lang      =     SYS_CONTEXT ('USERENV', 'LANG')
AND     flvc.lookup_type      =     'XXCMM_CUST_GYOTAI_CHU'
AND     flvc.lookup_code      =     flvs.attribute1
AND     flvc.enabled_flag     =     'Y'
AND     flvc.language         =     SYS_CONTEXT ('USERENV', 'LANG')
AND     flvc.source_lang      =     SYS_CONTEXT ('USERENV', 'LANG')
AND     flvd.lookup_type      =     'XXCMM_CUST_GYOTAI_DAI'
AND     flvd.lookup_code      =     flvc.attribute1
AND     flvd.enabled_flag     =     'Y'
AND     flvd.language         =     SYS_CONTEXT ('USERENV', 'LANG')
AND     flvd.source_lang      =     SYS_CONTEXT ('USERENV', 'LANG')
;
COMMENT ON  COLUMN  xxcos_business_conditions_v.d_lookup_code           IS  '�啪�ރR�[�h';
COMMENT ON  COLUMN  xxcos_business_conditions_v.d_meaning               IS  '�啪�ޖ���';
COMMENT ON  COLUMN  xxcos_business_conditions_v.d_start_date_active     IS  '�啪�ޓK�p�J�n��';
COMMENT ON  COLUMN  xxcos_business_conditions_v.d_end_date_active       IS  '�啪�ޓK�p�I����';
COMMENT ON  COLUMN  xxcos_business_conditions_v.c_lookup_code           IS  '�����ރR�[�h';
COMMENT ON  COLUMN  xxcos_business_conditions_v.c_meaning               IS  '�����ޖ���';
COMMENT ON  COLUMN  xxcos_business_conditions_v.c_start_date_active     IS  '�����ޓK�p�J�n��';
COMMENT ON  COLUMN  xxcos_business_conditions_v.c_end_date_active       IS  '�����ޓK�p�I����';
COMMENT ON  COLUMN  xxcos_business_conditions_v.s_lookup_code           IS  '�����ރR�[�h';
COMMENT ON  COLUMN  xxcos_business_conditions_v.s_meaning               IS  '�����ޖ���';
COMMENT ON  COLUMN  xxcos_business_conditions_v.s_start_date_active     IS  '�����ޓK�p�J�n��';
COMMENT ON  COLUMN  xxcos_business_conditions_v.s_end_date_active       IS  '�����ޓK�p�I����';
--
COMMENT ON  TABLE   xxcos_business_conditions_v                         IS  '�Ƒԕ��ރr���[';
