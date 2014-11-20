/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_USER_BASE_INFO_V
 * Description : �����_���r���[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   H.Sasaki         �V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       �J�����R�����g�A�o�b�N�X���b�V����ǉ�
 *
 ************************************************************************/
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_USER_BASE_INFO_V" ("ACCOUNT_ID", "ACCOUNT_NUMBER", "ACCOUNT_NAME", "MANAGEMENT_BASE_CODE", "MANAGEMENT_BASE_FLAG", "DEPT_HHT_DIV") AS 
  SELECT  CASE WHEN hca2.customer_id  IS NOT NULL THEN  hca2.customer_id
                   ELSE hca1.cust_account_id
              END   cust_account_id         -- �ڋqID
             ,CASE WHEN hca2.customer_id  IS NOT NULL THEN  hca2.account_number
                   ELSE hca1.account_number
              END   account_number          -- ���_�R�[�h
             ,CASE WHEN hca2.customer_id  IS NOT NULL THEN  hca2.account_name
                   ELSE hca1.account_name
              END   account_name            -- ���_����
             ,CASE WHEN hca2.customer_id  IS NOT NULL THEN  hca2.management_base_code
                   ELSE xca1.management_base_code
              END  management_base_code     -- �Ǘ������_
             ,CASE WHEN hca2.customer_id  IS NOT NULL AND hca2.account_number = hca2.management_base_code THEN  '1'
                   ELSE '0'
              END   management_base_flag    -- �Ǘ������_�t���O�i1:�Ǘ������_�A0:�Ǌ����_�j
             ,CASE WHEN hca2.customer_id  IS NOT NULL THEN  hca2.dept_hht_div
                   ELSE xca1.dept_hht_div
              END   dept_hht_div            -- HHT�敪�i1:�S�ݓX�j
      FROM    hz_cust_accounts    hca1
             ,xxcmm_cust_accounts xca1
             ,(SELECT   xca.customer_id
                       ,hca.account_number
                       ,hca.account_name
                       ,xca.management_base_code
                       ,xca.dept_hht_div
               FROM     hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
               WHERE    hca.cust_account_id       =   xca.customer_id
               AND      hca.customer_class_code   =   '1'           -- ���_
               AND      hca.status                =   'A'           -- �L��
              )                   hca2                              -- �Ǌ����_���
      WHERE   hca1.account_number           =
                  (SELECT CASE WHEN TO_DATE(paa.ASS_ATTRIBUTE2, 'YYYYMMDD') > xpd.process_date
                                  THEN  ASS_ATTRIBUTE6
                               ELSE     ASS_ATTRIBUTE5
                          END
                   FROM   per_all_assignments_f     paa
                         ,fnd_user                  fu
                         ,(SELECT  CASE WHEN oap.period_start_date = TO_CHAR(xxccp_common_pkg2.get_process_date, 'YYYYMM') THEN xxccp_common_pkg2.get_process_date
                                        ELSE LAST_DAY(TO_DATE(oap.period_start_date, 'YYYYMM'))
                                   END  process_date
                           FROM    (SELECT  MIN(TO_CHAR(sub_oap.period_start_date, 'YYYYMM'))  period_start_date
                                    FROM    org_acct_periods      sub_oap
                                    WHERE   sub_oap.organization_id       =   xxcoi_common_pkg.get_organization_id(fnd_profile.value('XXCOI1_ORGANIZATION_CODE'))
                                            AND     sub_oap.open_flag     =   'Y'
                                   )  oap
                          )                         xpd
                   WHERE  fu.user_id        =   fnd_global.user_id
                   AND    paa.person_id     =   fu.employee_id
                   AND    paa.effective_start_date
                                            =   (SELECT MAX(paa2.effective_start_date)
                                                 FROM   per_all_assignments_f   paa2
                                                       ,fnd_user                fu2
                                                 WHERE  fu2.user_id     =   fnd_global.user_id
                                                 AND    paa2.person_id  =   fu2.employee_id
                                                )
                  )                       -- ���O�C�����[�U�̎����_
      AND     hca1.customer_class_code      =   '1'           -- ���_
      AND     hca1.status                   =   'A'           -- �L��
      AND     hca1.cust_account_id          =   xca1.customer_id
      AND     hca1.account_number           =   hca2.management_base_code(+)
/
COMMENT ON TABLE  XXCOI_USER_BASE_INFO_V                         IS '�����_���r���[';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO_V.ACCOUNT_ID              IS '�ڋqID';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO_V.ACCOUNT_NUMBER          IS '���_�R�[�h';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO_V.ACCOUNT_NAME            IS '���_����';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO_V.MANAGEMENT_BASE_CODE    IS '�Ǘ������_';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO_V.MANAGEMENT_BASE_FLAG    IS '�Ǘ������_�t���O';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO_V.DEPT_HHT_DIV            IS 'HHT�敪';
/
