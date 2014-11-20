/*************************************************************************
 * 
 * View  Name      : XXSKZ_���̎󒍃w�b�__��{_V
 * Description     : XXSKZ_���̎󒍃w�b�__��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���̎󒍃w�b�__��{_V
(
   �X�e�[�^�X
  ,�󒍃^�C�v
  ,�R���e�L�X�g�l
  ,������
  ,�����於
  ,�󒍔ԍ�
  ,�[�i�\���
  ,�ڋq�R�[�h
  ,�ڋq��
  ,�ڋq_�Z��
  ,���_�R�[�h
  ,���_����
  ,"���Ԏw��iFrom�j"
  ,"���Ԏw��iTo�j"
  ,�E�v
  ,�I�[�_�[No
  ,�󒍓�
  ,�S���c�ƈ�
  ,�ڋq�����ԍ�
)
AS
SELECT
        CASE ooha.flow_status_code 
        WHEN 'ENTERED'    THEN  '���͍�'
        WHEN 'CANCELLED'  THEN  '���'
        WHEN 'CLOSED'     THEN  '�N���[�Y'
        WHEN 'BOOKED'     THEN  '�L����'
        ELSE '�|'
        END                                           �X�e�[�^�X
      , ottt.name                                     �󒍃^�C�v
      , ooha.context                                  �R���e�L�X�g�l
      , s_hca.account_number                          ������
      , s_hp.party_name                               �����於
      , ooha.order_number                             �󒍔ԍ�
      , ooha.request_date                             �[�i�\���
      , k_hca.account_number                          �ڋq�R�[�h
      , k_hp.party_name                               �ڋq��
      , k_hl.address1                                 �ڋq_�Z��
      , k_hca.attribute17                             ���_�R�[�h
      , xca2v2.party_name                             ���_����
      , ooha.attribute13                              "���Ԏw��iFrom�j"
      , ooha.attribute14                              "���Ԏw��iTo�j"
      , ooha.shipping_instructions                    �E�v
      , ooha.attribute19                              �I�[�_�[No
      , ooha.ordered_date                             �󒍓�
      , papf.full_name                                �S���c�ƈ�
      , ooha.cust_po_number                           �ڋq�����ԍ�
FROM    oe_order_headers_all          ooha    --�󒍃w�b�_�e�[�u��
      , oe_transaction_types_tl       ottt    -- �󒍃^�C�v�}�X�^(���{��)
      -- �c�ƒS��
      , jtf_rs_resource_extns         jrre    -- ���\�[�X�}�X�^
      , per_all_people_f              papf    -- �]�ƈ��}�X�^
      , jtf_rs_salesreps              jrs     -- jtf_rs_salesreps
      -- �ڋq���
      , hz_cust_accounts              k_hca
      , hz_parties                    k_hp
      , hz_cust_site_uses_all         k_hcsua
      , hz_cust_acct_sites_all        k_hcasa
      , hz_party_sites                k_hps
      , hz_locations                  k_hl
      , xxcmn_cust_accounts2_v        xca2v2
      -- ��������
      , hz_cust_site_uses_all         s_hcaua
      , hz_cust_acct_sites_all        s_hcasa
      , hz_cust_accounts              s_hca
      , hz_parties                    s_hp
      -- �c�ƒP��
      , hr_all_organization_units     haou
WHERE 
--�󒍃^�C�v���擾
     ottt.language      = 'JA'
AND  ooha.order_type_id = OTTT.transaction_type_id
-- �S���Җ�
AND  ooha.salesrep_id   = jrs.salesrep_id
AND  jrs.resource_id    = jrre.resource_id
AND  jrre.source_id     = papf.person_id
AND  ooha.request_date BETWEEN TRUNC(papf.effective_start_date)
                           AND TRUNC(NVL(papf.effective_end_date, ooha.request_date))
-- �ڋq���
AND   ooha.sold_to_org_id        = k_hca.cust_account_id
AND   k_hca.party_id             = k_hp.party_id
AND   ooha.ship_to_org_id        = k_hcsua.site_use_id
AND   k_hcsua.site_use_code      = 'SHIP_TO'
AND   k_hcsua.cust_acct_site_id  = k_hcasa.cust_acct_site_id
AND   k_hcasa.party_site_id      = k_hps.party_site_id
AND   k_hps.location_id          = k_hl.location_id
-- �������㋒�_��
AND   k_hca.attribute17          = xca2v2.party_number
AND   ooha.request_date BETWEEN xca2v2.start_date_active
                            AND xca2v2.end_date_active
-- ��������
AND   ooha.invoice_to_org_id    = s_hcaua.site_use_id
AND   s_hcaua.cust_acct_site_id = s_hcasa.cust_acct_site_id
AND   s_hcasa.cust_account_id   = s_hca.cust_account_id
AND   s_hca.party_id            = s_hp.party_id
-- ���_�R�[�h�i���ŕ��w�� �N�C�b�N�R�[�h��`�j
AND   EXISTS (
              SELECT 'x'
              FROM  xxcmn_lookup_values_v xlvv
              WHERE xlvv.lookup_type = 'XXCMN_SALE_SKYLINK_BRANCH'
              AND   xlvv.lookup_code = k_hca.attribute17
             )
-- �c�Ƒg�D
AND   haou.type    = 'OU'
AND   haou.name    = 'SALES-OU'
-- �c�� �g�DID
AND   ooha.org_id  = haou.organization_id
/
COMMENT ON TABLE APPS.XXSKZ_���̎󒍃w�b�__��{_V IS 'SKYLINK�p ���̎󒍃w�b�_(��{)VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�X�e�[�^�X IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�󒍃^�C�v IS '�󒍃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�R���e�L�X�g�l IS '�R���e�L�X�g�l'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�����於 IS '�����於'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�󒍔ԍ� IS '�󒍔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�[�i�\��� IS '�[�i�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�ڋq�R�[�h IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�ڋq�� IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�ڋq_�Z�� IS '�ڋq_�Z��'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.���_�R�[�h IS '���_�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.���_���� IS '���_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V."���Ԏw��iFrom�j" IS '���Ԏw��iFrom�j'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V."���Ԏw��iTo�j" IS '���Ԏw��iTo�j'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�E�v IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�I�[�_�[No IS '�I�[�_�[No'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�󒍓� IS '�󒍓�'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�S���c�ƈ� IS '�S���c�ƈ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���̎󒍃w�b�__��{_V.�ڋq�����ԍ� IS '�ڋq�����ԍ�'
/
