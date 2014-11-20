/*************************************************************************
 * 
 * View  Name      : XXSKZ_�^������_��{_V
 * Description     : XXSKZ_�^������_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�^������_��{_V
(
 ���i�敪
,���i�敪��
,�^���Ǝ�
,�^���ƎҖ�
,������
,�����於
,�N��
,�x�����ڂP
,�x�����ڂP��
,�x�����z�P
,�x����ېłP
,�x�����ڂQ
,�x�����ڂQ��
,�x�����z�Q
,�x����ېłQ
,�x�����ڂR
,�x�����ڂR��
,�x�����z�R
,�x����ېłR
,�x�����ڂS
,�x�����ڂS��
,�x�����z�S
,�x����ېłS
,�x�����ڂT
,�x�����ڂT��
,�x�����z�T
,�x����ېłT
,����Œ���
,�������ڂP
,�������ڂP��
,�������z�P
,������ېłP
,�������ڂQ
,�������ڂQ��
,�������z�Q
,������ېłQ
,�������ڂR
,�������ڂR��
,�������z�R
,������ېłR
,�������ڂS
,�������ڂS��
,�������z�S
,������ېłS
,�������ڂT
,�������ڂT��
,�������z�T
,������ېłT
,��ېŐ������z���v
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        XAC.goods_classe                                    --���i�敪
       ,FLV01.meaning           goods_classe_name           --���i�敪��
       ,XAC.delivery_company_code                           --�^���Ǝ�
       ,XC2V.party_name         carrier_name                --�^���ƎҖ�
       ,XAC.billing_code                                    --������
       ,XL2V.location_name      billing_name                --�����於
       ,XAC.billing_date                                    --�N��
       ,XAC.item_payment1                                   --�x�����ڂP
       ,FLV02.meaning           item_payment1_name          --�x�����ڂP��
       ,XAC.amount_payment1                                 --�x�����z�P
       ,XAC.tax_free_payment1                               --�x����ېłP
       ,XAC.item_payment2                                   --�x�����ڂQ
       ,FLV03.meaning           item_payment2_name          --�x�����ڂQ��
       ,XAC.amount_payment2                                 --�x�����z�Q
       ,XAC.tax_free_payment2                               --�x����ېłQ
       ,XAC.item_payment3                                   --�x�����ڂR
       ,FLV04.meaning           item_payment3_name          --�x�����ڂR��
       ,XAC.amount_payment3                                 --�x�����z�R
       ,XAC.tax_free_payment3                               --�x����ېłR
       ,XAC.item_payment4                                   --�x�����ڂS
       ,FLV05.meaning           item_payment4_name          --�x�����ڂS��
       ,XAC.amount_payment4                                 --�x�����z�S
       ,XAC.tax_free_payment4                               --�x����ېłS
       ,XAC.item_payment5                                   --�x�����ڂT
       ,FLV06.meaning           item_payment5_name          --�x�����ڂT��
       ,XAC.amount_payment5                                 --�x�����z�T
       ,XAC.tax_free_payment5                               --�x����ېłT
       ,XAC.adj_tax_extra                                   --����Œ���
       ,XAC.item_billing1                                   --�������ڂP
       ,FLV07.meaning           item_billing1_name          --�������ڂP��
       ,XAC.amount_billing1                                 --�������z�P
       ,XAC.tax_free_billing1                               --������ېłP
       ,XAC.item_billing2                                   --�������ڂQ
       ,FLV08.meaning           item_billing2_name          --�������ڂQ��
       ,XAC.amount_billing2                                 --�������z�Q
       ,XAC.tax_free_billing2                               --������ېłQ
       ,XAC.item_billing3                                   --�������ڂR
       ,FLV09.meaning           item_billing3_name          --�������ڂR��
       ,XAC.amount_billing3                                 --�������z�R
       ,XAC.tax_free_billing3                               --������ېłR
       ,XAC.item_billing4                                   --�������ڂS
       ,FLV10.meaning           item_billing4_name          --�������ڂS��
       ,XAC.amount_billing4                                 --�������z�S
       ,XAC.tax_free_billing4                               --������ېłS
       ,XAC.item_billing5                                   --�������ڂT
       ,FLV11.meaning           item_billing5_name          --�������ڂT��
       ,XAC.amount_billing5                                 --�������z�T
       ,XAC.tax_free_billing5                               --������ېłT
       ,XAC.no_tax_billing_total                            --��ېŐ������z���v
       ,FU_CB.user_name         created_by_name             --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XAC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date               --�쐬����
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XAC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date            --�X�V����
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxwip_adj_charges       XAC                         --�^�������A�h�I���C���^�t�F�[�X
       ,xxskz_carriers2_v       XC2V                        --SKYLINK�p����VIEW �^���ƎҎ擾VIEW
       ,xxskz_locations2_v      XL2V                        --SKYLINK�p����VIEW ������擾VIEW
       ,fnd_lookup_values       FLV01                       --���i�敪���擾�p
       ,fnd_lookup_values       FLV02                       --�x�����ڂP���擾�p
       ,fnd_lookup_values       FLV03                       --�x�����ڂQ���擾�p
       ,fnd_lookup_values       FLV04                       --�x�����ڂR���擾�p
       ,fnd_lookup_values       FLV05                       --�x�����ڂS���擾�p
       ,fnd_lookup_values       FLV06                       --�x�����ڂT���擾�p
       ,fnd_lookup_values       FLV07                       --�������ڂP���擾�p
       ,fnd_lookup_values       FLV08                       --�������ڂQ���擾�p
       ,fnd_lookup_values       FLV09                       --�������ڂR���擾�p
       ,fnd_lookup_values       FLV10                       --�������ڂS���擾�p
       ,fnd_lookup_values       FLV11                       --�������ڂT���擾�p
       ,fnd_user                FU_CB                       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU                       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL                       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL                       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
    --�^���ƎҖ��擾����
        XC2V.freight_code(+)        =  XAC.delivery_company_code
   AND  XC2V.start_date_active(+)   <= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
   AND  XC2V.end_date_active(+)     >= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
    --�����於�擾����
   AND  XL2V.location_code(+)       =  XAC.billing_code
   AND  XL2V.start_date_active(+)   <= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
   AND  XL2V.end_date_active(+)     >= LAST_DAY(TO_DATE(XAC.billing_date || '01', 'YYYYMMDD'))
    --���i�敪���擾����
   AND  FLV01.language(+)           = 'JA'
   AND  FLV01.lookup_type(+)        = 'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)        = XAC.goods_classe
    --�x�����ڂP���擾����
   AND  FLV02.language(+)           = 'JA'
   AND  FLV02.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV02.lookup_code(+)        = XAC.item_payment1
    --�x�����ڂQ���擾����
   AND  FLV03.language(+)           = 'JA'
   AND  FLV03.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV03.lookup_code(+)        = XAC.item_payment2
    --�x�����ڂR���擾����
   AND  FLV04.language(+)           = 'JA'
   AND  FLV04.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV04.lookup_code(+)        = XAC.item_payment3
    --�x�����ڂS���擾����
   AND  FLV05.language(+)           = 'JA'
   AND  FLV05.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV05.lookup_code(+)        = XAC.item_payment4
    --�x�����ڂT���擾����
   AND  FLV06.language(+)           = 'JA'
   AND  FLV06.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV06.lookup_code(+)        = XAC.item_payment5
    --�������ڂP���擾����
   AND  FLV07.language(+)           = 'JA'
   AND  FLV07.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV07.lookup_code(+)        = XAC.item_billing1
    --�������ڂQ���擾����
   AND  FLV08.language(+)           = 'JA'
   AND  FLV08.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV08.lookup_code(+)        = XAC.item_billing2
    --�������ڂR���擾����
   AND  FLV09.language(+)           = 'JA'
   AND  FLV09.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV09.lookup_code(+)        = XAC.item_billing3
    --�������ڂS���擾����
   AND  FLV10.language(+)           = 'JA'
   AND  FLV10.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV10.lookup_code(+)        = XAC.item_billing4
    --�������ڂT���擾����
   AND  FLV11.language(+)           = 'JA'
   AND  FLV11.lookup_type(+)        = 'XXWIP_PAY_BILL_ITEM'
   AND  FLV11.lookup_code(+)        = XAC.item_billing5
   --WHO�J�����擾
   AND  XAC.created_by              = FU_CB.user_id(+)
   AND  XAC.last_updated_by         = FU_LU.user_id(+)
   AND  XAC.last_update_login       = FL_LL.login_id(+)
   AND  FL_LL.user_id               = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�^������_��{_V                     IS 'SKYLINK�p�^�������i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�^���Ǝ�           IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�^���ƎҖ�         IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.������             IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�����於           IS '�����於'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�N��               IS '�N��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂP         IS '�x�����ڂP'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂP��       IS '�x�����ڂP��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����z�P         IS '�x�����z�P'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x����ېłP       IS '�x����ېłP'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂQ         IS '�x�����ڂQ'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂQ��       IS '�x�����ڂQ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����z�Q         IS '�x�����z�Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x����ېłQ       IS '�x����ېłQ'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂR         IS '�x�����ڂR'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂR��       IS '�x�����ڂR��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����z�R         IS '�x�����z�R'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x����ېłR       IS '�x����ېłR'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂS         IS '�x�����ڂS'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂS��       IS '�x�����ڂS��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����z�S         IS '�x�����z�S'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x����ېłS       IS '�x����ېłS'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂT         IS '�x�����ڂT'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����ڂT��       IS '�x�����ڂT��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x�����z�T         IS '�x�����z�T'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�x����ېłT       IS '�x����ېłT'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.����Œ���         IS '����Œ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂP         IS '�������ڂP'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂP��       IS '�������ڂP��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������z�P         IS '�������z�P'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.������ېłP       IS '������ېłP'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂQ         IS '�������ڂQ'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂQ��       IS '�������ڂQ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������z�Q         IS '�������z�Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.������ېłQ       IS '������ېłQ'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂR         IS '�������ڂR'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂR��       IS '�������ڂR��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������z�R         IS '�������z�R'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.������ېłR       IS '������ېłR'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂS         IS '�������ڂS'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂS��       IS '�������ڂS��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������z�S         IS '�������z�S'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.������ېłS       IS '������ېłS'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂT         IS '�������ڂT'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������ڂT��       IS '�������ڂT��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�������z�T         IS '�������z�T'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.������ېłT       IS '������ېłT'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.��ېŐ������z���v IS '��ېŐ������z���v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^������_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/