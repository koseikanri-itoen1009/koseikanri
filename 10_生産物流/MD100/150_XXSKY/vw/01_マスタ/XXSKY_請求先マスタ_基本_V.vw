CREATE OR REPLACE VIEW APPS.XXSKY_������}�X�^_��{_V
(
 ������R�[�h
,�����N��
,�����於
,�X�֔ԍ�
,�Z��
,�d�b�ԍ�
,FAX�ԍ�
,�U����
,�x�������ݒ��
,�O�������z
,��������z
,�����z
,�J�z�z
,���񐿋����z
,�������z���v
,��������z
,�����
,�ʍs����
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XBM.billing_code                --������R�[�h
       ,XBM.billing_date                --�����N��
       ,XBM.billing_name                --�����於
       ,XBM.post_no                     --�X�֔ԍ�
       ,XBM.address                     --�Z��
       ,XBM.telephone_no                --�d�b�ԍ�
       ,XBM.fax_no                      --FAX�ԍ�
       ,XBM.money_transfer_date         --�U����
       ,XBM.condition_setting_date      --�x�������ݒ��
       ,XBM.last_month_charge_amount    --�O�������z
       ,XBM.amount_receipt_money        --��������z
       ,XBM.amount_adjustment           --�����z
       ,XBM.balance_carried_forward     --�J�z�z
       ,XBM.charged_amount              --���񐿋����z
       ,XBM.charged_amount_total        --�������z���v
       ,XBM.month_sales                 --��������z
       ,XBM.consumption_tax             --�����
       ,XBM.congestion_charge           --�ʍs����
       ,FU_CB.user_name                 --�쐬��
       ,TO_CHAR( XBM.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --�쐬��
       ,FU_LU.user_name                 --�ŏI�X�V��
       ,TO_CHAR( XBM.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                        --�ŏI�X�V��
       ,FU_LL.user_name                 --�ŏI�X�V���O�C��
  FROM  xxwip_billing_mst   XBM         --������A�h�I���}�X�^
       ,fnd_user            FU_CB       --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user            FU_LU       --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user            FU_LL       --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins          FL_LL       --���O�C���}�X�^(last_update_login���̎擾�p)
 WHERE  XBM.created_by        = FU_CB.user_id(+)
   AND  XBM.last_updated_by   = FU_LU.user_id(+)
   AND  XBM.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_������}�X�^_��{_V IS 'SKYLINK�p������}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.������R�[�h      IS '������R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�����N��          IS '�����N��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�����於          IS '�����於'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�X�֔ԍ�          IS '�X�֔ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�Z��              IS '�Z��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�d�b�ԍ�          IS '�d�b�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.FAX�ԍ�           IS 'FAX�ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�U����            IS '�U����'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�x�������ݒ��    IS '�x�������ݒ��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�O�������z        IS '�O�������z'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.��������z        IS '��������z'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�����z            IS '�����z'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�J�z�z            IS '�J�z�z'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.���񐿋����z      IS '���񐿋����z'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�������z���v      IS '�������z���v'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.��������z        IS '��������z'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�����            IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�ʍs����          IS '�ʍs����'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�쐬��            IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�쐬��            IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�ŏI�X�V��        IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�ŏI�X�V��        IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_������}�X�^_��{_V.�ŏI�X�V���O�C��  IS '�ŏI�X�V���O�C��'
/