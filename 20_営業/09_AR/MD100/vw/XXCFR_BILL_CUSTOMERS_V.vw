CREATE OR REPLACE VIEW xxcfr_bill_customers_v(
/*************************************************************************
 * 
 * View Name       : XXCFR_BILL_CUSTOMERS_V
 * Description     : ������ڋq�r���[
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/11/27    1.0  SCS �g�� ���i ����쐬
 *  2009/04/07    1.1  SCS ��� �b   [��QT1_0383] �擾�ڋq�s���Ή�
 ************************************************************************/
  pay_customer_id,                   -- ������ڋqID
  pay_customer_number,               -- ������ڋq�R�[�h
  pay_customer_name,                 -- ������ڋq��
  receiv_base_code,                  -- �������_�R�[�h
  receiv_base_name,                  -- �������_��
  receiv_code1,                      -- ���|�R�[�h1�i�������j
  bill_customer_id,                  -- ������ڋqID
  bill_customer_code,                -- ������ڋq�R�[�h
  bill_customer_name,                -- ������ڋq��
  bill_base_code,                    -- �������_�R�[�h
  bill_base_name,                    -- �������_��
  store_code,                        -- ������ڋq�X�R�[�h
  tax_div,                           -- ����ŋ敪
  tax_rounding_rule,                 -- �ŋ�-�[������
  inv_prt_type,                      -- �������o�͌`��
  cons_inv_flag,                     -- �ꊇ���������s�t���O
  org_id                             -- �g�DID
)
AS
  SELECT  NVL(chcar.cust_account_id,bcus.cust_account_id) pay_customer_id,
          NVL(chca.account_number,bcus.customer_code) pay_customer_number,
          NVL(chp.party_name,bcus.customer_name)  pay_customer_name,
          NVL(cxca.receiv_base_code,bcus.bill_base_code) receiv_base_code,
          NVL(cffvv.description,bcus.bill_base_name) receiv_base_name,
          bcus.receiv_code1,
          bcus.cust_account_id,
          bcus.customer_code  bill_customer_code,
          bcus.customer_name  bill_customer_name,
          bcus.bill_base_code,
          bcus.bill_base_name,
          bcus.store_code,
          bcus.tax_div,
          bcus.tax_rounding_rule,
          bcus.inv_prt_type,
          bcus.cons_inv_flag,
          NVL(chcar.org_id,bcus.org_id) org_id
  FROM    hz_cust_acct_relate_all chcar,     -- �ڋq�֘A�i������-������j
          hz_cust_accounts        chca,      -- �ڋq�i������j
          hz_parties              chp,       -- �p�[�e�B�i������j
          xxcmm_cust_accounts     cxca,      -- �ڋq�A�h�I���i������j
          (SELECT  flex_value,
                   description
           FROM    fnd_flex_values_vl ffv
           WHERE   EXISTS
                   (SELECT  'X'
                    FROM    fnd_flex_value_sets
                    WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                    AND     flex_value_set_id   = ffv.flex_value_set_id)) cffvv,  --�l�Z�b�g�l�i��������j
          (
           --������
           SELECT  xhca.cust_account_id,        --������ڋqID
                   xhcp.cust_account_profile_id,
                   xhcas.cust_acct_site_id,
                   xhcsu.site_use_id,
                   xhca.party_id,
                   xhp.party_number,
                   xhcsu.attribute4          receiv_code1,         --���|�R�[�h1�i������j
                   xhca.account_number       customer_code,            --������ڋq�R�[�h
                   xhp.party_name            customer_name,            --������ڋq����
                   xhca.status               status,                   --�ڋq�X�e�[�^�X
                   xhca.customer_type        customer_type,            --�ڋq�^�C�v
                   xhca.customer_class_code  customer_class_code,      --�ڋq�敪
                   xxca.bill_base_code       bill_base_code,           --�������_�R�[�h
                   xffvv.description         bill_base_name,           --�������_��
                   xxca.store_code           store_code,               --�X�܃R�[�h
                   xxca.tax_div              tax_div,                  --����ŋ敪
                   xhcsu.tax_rounding_rule   tax_rounding_rule,        --�ŋ��|�[������
                   xhcsu.attribute7          inv_prt_type,             --�������o�͌`��
                   xhcp.cons_inv_flag        cons_inv_flag,            --�ꊇ���������s�敪
                   xhcas.org_id              org_id                    --�g�DID
           FROM    hz_cust_accounts        xhca,                       --�ڋq�A�J�E���g�i������j
                   hz_parties              xhp,                        --�p�[�e�B�i������j
                   hz_cust_acct_sites_all  xhcas,                      --�ڋq�T�C�g�i������j
                   hz_cust_site_uses_all   xhcsu,                      --�ڋq�g�p�ړI�i������j
                   hz_customer_profiles    xhcp,                       --�ڋq�v���t�@�C���i������j
                   xxcmm_cust_accounts     xxca,                       --�ڋq�A�h�I���i������j
                   (SELECT flex_value,
                           description 
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  --�l�Z�b�g�l�i��������j
           WHERE   xhca.party_id            = xhp.party_id               
           AND     xhca.customer_class_code = '14'
-- Modify 2009.04.07 Ver1.1 Start
--           AND     xhca.status              = 'A'                       --�X�e�[�^�X
-- Modify 2009.04.07 Ver1.1 END
           AND     xhca.cust_account_id     = xhcas.cust_account_id
-- Modify 2009.04.07 Ver1.1 Start
           AND     xhcas.org_id             = fnd_profile.value('ORG_ID') -- ������ڋq���ݒn
-- Modify 2009.04.07 Ver1.1 END
           AND     xhcas.bill_to_flag       IS NOT NULL                 --
           AND     xhcas.cust_acct_site_id  = xhcsu.cust_acct_site_id
           AND     xhcsu.site_use_code      = 'BILL_TO'                 --�g�p�ړI
-- Modify 2009.04.07 Ver1.1 Start
           AND     xhcsu.primary_flag       = 'Y'
           AND     xhcsu.status             = 'A'                       --�X�e�[�^�X
-- Modify 2009.04.07 Ver1.1 END
           AND     xhca.cust_account_id     = xhcp.cust_account_id
           AND     xhcp.site_use_id         IS NULL
           AND     xhca.cust_account_id     = xxca.customer_id(+)
           AND     xxca.bill_base_code      = xffvv.flex_value(+)
           AND     EXISTS
                   (SELECT   'X'
                    FROM     hz_cust_acct_relate_all hcar
                    WHERE    hcar.attribute1  = '1'
                    AND      hcar.status      = 'A'
                    AND      hcar.cust_account_id = xhca.cust_account_id
                    )
         UNION ALL
           -- �[�i�� AND ������
           SELECT  yhca.cust_account_id,                               --������ڋqid
                   yhcp.cust_account_profile_id,
                   yhcas.cust_acct_site_id,
                   yhcsu.site_use_id,
                   yhca.party_id,
                   yhp.party_number,
                   yhcsu.attribute4          receiv_code1,         --���|�R�[�h1�i������j
                   yhca.account_number       customer_code,            --������ڋq�R�[�h
                   yhp.party_name            customer_name,            --������ڋq����
                   yhca.status               status,                   --�ڋq�X�e�[�^�X
                   yhca.customer_type        customer_type,            --�ڋq�^�C�v
                   yhca.customer_class_code  customer_class_code,      --�ڋq�敪
                   yxca.bill_base_code       bill_base_code,           --�������_�R�[�h
                   yffvv.description         bill_base_name,           --�������_��
                   yxca.store_code           store_code,               --�X�܃R�[�h
                   yxca.tax_div              tax_div,                  --����ŋ敪
                   yhcsu.tax_rounding_rule   tax_rounding_rule,        --�ŋ��|�[������
                   yhcsu.attribute7          inv_prt_type,             --�������o�͌`��
                   yhcp.cons_inv_flag        cons_inv_flag,            --�ꊇ���������s�敪
                   yhcas.org_id              org_id                    --�g�DID
           FROM    hz_cust_accounts        yhca,                       --�ڋq�A�J�E���g�i������j
                   hz_parties              yhp,                        --�p�[�e�B�i������j
                   hz_cust_acct_sites_all  yhcas,                      --�ڋq�T�C�g�i������j
                   hz_cust_site_uses_all   yhcsu,                      --�ڋq�g�p�ړI�i������j
                   hz_customer_profiles    yhcp,                       --�ڋq�v���t�@�C���i������j
                   xxcmm_cust_accounts     yxca,                       --�ڋq�A�h�I���i������j
                   (SELECT  flex_value,
                           description 
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT   'X'
                            FROM     fnd_flex_value_sets
                            WHERE    flex_value_set_name = 'XX03_DEPARTMENT'
                            AND      flex_value_set_id = ffv.flex_value_set_id)) yffvv  --�l�Z�b�g�l�i��������j
           WHERE   yhca.party_id            = yhp.party_id               
           AND     yhca.customer_class_code = '10'
-- Modify 2009.04.07 Ver1.1 Start
--           AND     yhca.status              = 'A'                       --�X�e�[�^�X
-- Modify 2009.04.07 Ver1.1 END
           AND     yhca.cust_account_id     = yhcas.cust_account_id
           AND     yhcas.bill_to_flag       IS NOT NULL                 --
           AND     yhcas.cust_acct_site_id  = yhcsu.cust_acct_site_id
-- Modify 2009.04.07 Ver1.1 Start
           AND     yhcas.org_id             = fnd_profile.value('ORG_ID') -- ������ڋq���ݒn
-- Modify 2009.04.07 Ver1.1 END
           AND     yhcsu.site_use_code      = 'BILL_TO'                 --�g�p�ړI
-- Modify 2009.04.07 Ver1.1 Start
           AND     yhcsu.primary_flag       = 'Y'
           AND     yhcsu.status             = 'A'                       --�X�e�[�^�X
-- Modify 2009.04.07 Ver1.1 END
           AND     yhca.cust_account_id     = yhcp.cust_account_id
           AND     yhcp.site_use_id         IS NULL
           AND     yhca.cust_account_id     = yxca.customer_id(+)
           AND     yxca.bill_base_code      = yffvv.flex_value(+)
           AND     NOT EXISTS
                   (SELECT   'X'
                    FROM     hz_cust_acct_relate_all hcar
                    WHERE    hcar.attribute1  = '1'
                    AND      hcar.status      = 'A'
                    AND      hcar.related_cust_account_id = yhca.cust_account_id
                   )
          ) bcus
  WHERE   chcar.related_cust_account_id(+) = bcus.cust_account_id
  AND     chcar.org_id(+)                  = bcus.org_id
  AND     chcar.cust_account_id            = chca.cust_account_id(+)
  AND     chca.party_id                    = chp.party_id(+)
  AND     chca.cust_account_id             = cxca.customer_id(+)
  AND     cxca.receiv_base_code            = cffvv.flex_value(+)
  AND     chcar.status(+)                  = 'A'
;

COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_id        IS '������ڋqID';
COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_number    IS '������ڋq�R�[�h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_name      IS '������ڋq��';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_base_code       IS '�������_�R�[�h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_base_name       IS '�������_��';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_code1           IS '���|�R�[�h1�i�������j';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_id       IS '������ڋqID';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_code     IS '������ڋq�R�[�h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_name     IS '������ڋq��';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_base_code         IS '�������_�R�[�h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_base_name         IS '�������_��';
COMMENT ON COLUMN  xxcfr_bill_customers_v.store_code             IS '������ڋq�X�R�[�h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.tax_div                IS '����ŋ敪';
COMMENT ON COLUMN  xxcfr_bill_customers_v.tax_rounding_rule      IS '�ŋ�';
COMMENT ON COLUMN  xxcfr_bill_customers_v.inv_prt_type           IS '�������o�͌`��';
COMMENT ON COLUMN  xxcfr_bill_customers_v.cons_inv_flag          IS '�ꊇ���������s�t���O';
COMMENT ON COLUMN  xxcfr_bill_customers_v.org_id                 IS '�g�DID';

COMMENT ON TABLE  xxcfr_bill_customers_v IS '������ڋq�r���[';
