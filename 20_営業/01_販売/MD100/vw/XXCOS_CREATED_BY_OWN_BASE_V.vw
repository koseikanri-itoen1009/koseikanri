/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOS_CREATED_BY_OWN_BASE_V
 * Description     : �S���[�U�������鎩���_�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/1/21     1.0   T.Tyou           �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_created_by_own_base_v (
  base_code,                            --���_�R�[�h
  user_id                               --���[�UID
)
AS 
 SELECT
    hca.account_number                  base_code,
    obc.user_id                         user_id
  FROM
    hz_cust_accounts                    hca,
    hz_parties                          hp,
    ( SELECT
        CASE
          WHEN pd.process_date          >= TRUNC(
                                             NVL(  FND_DATE.STRING_TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
                                               pd.process_date
                                             )
                                           )
          THEN paaf.ass_attribute5
          ELSE paaf.ass_attribute4
        END                             own_base_code,
        pd.process_date                 process_date,
        fu.user_id                      user_id
      FROM
        fnd_user                        fu,  
        per_all_people_f                papf, 
        per_all_assignments_f           paaf, 
        per_person_types                ppt, 
        (
          SELECT
            TRUNC( xxccp_common_pkg2.get_process_date )     process_date     
          FROM
            dual
        )                               pd                             
      WHERE 
      --fu.user_id                  = NVL( :order.created_by, fnd_global.user_id )
      fu.employee_id                    = papf.person_id
      AND papf.person_id                = paaf.person_id
      AND pd.process_date               >= papf.effective_start_date
      AND pd.process_date               <= papf.effective_end_date
      AND pd.process_date               >= paaf.effective_start_date
      AND pd.process_date               <= paaf.effective_end_date
      AND ppt.business_group_id         = fnd_global.per_business_group_id
      AND ppt.system_person_type        = 'EMP'
      AND ppt.active_flag               = 'Y'
      AND papf.person_type_id           = ppt.person_type_id
    )                                   obc
  WHERE hca.party_id                    = hp.party_id
  AND hca.account_number                = obc.own_base_code
  AND hca.customer_class_code           = '1'
  AND obc.process_date                  >= TRUNC(
                                             NVL(  FND_DATE.STRING_TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
                                               obc.process_date
                                             )
                                           )
;
COMMENT ON  COLUMN  xxcos_created_by_own_base_v.base_code       IS  '���_�R�[�h';
COMMENT ON  COLUMN  xxcos_created_by_own_base_v.user_id         IS  '���[�UID';
--
COMMENT ON  TABLE   xxcos_created_by_own_base_v                 IS  '�S���[�U�������鎩���_�r���[';
