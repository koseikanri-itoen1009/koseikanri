CREATE OR REPLACE VIEW APPS.XXSKY_�^���p�^���Ǝ�_��{_V
(
 ���i�敪
,���i�敪��
,�^���Ǝ҃R�[�h
,�^���ƎҖ�
,�K�p�J�n��
,�K�p�I����
,�I�����C�����Ή��敪
,�I�����C�����Ή��敪��
,�������ߓ�
,����ŋ敪
,����ŋ敪��
,�l�̌ܓ��敪
,�l�̌ܓ��敪��
,�x�����f�敪
,�x�����f�敪��
,������R�[�h
,�����於
,�����
,�������
,�����d��
,�x���s�b�L���O�P��
,�����s�b�L���O�P��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        XDC.goods_classe               --���i�敪
       ,FLV01.meaning                  --���i�敪��
       ,XDC.delivery_company_code      --�^���Ǝ҃R�[�h
       ,XCRV.party_name                --�^���ƎҖ�
       ,XDC.start_date_active          --�K�p�J�n��
       ,XDC.end_date_active            --�K�p�I����
       ,XDC.online_classe              --�I�����C�����Ή��敪
       ,FLV02.meaning                  --�I�����C�����Ή��敪��
       ,XDC.due_billing_date           --�������ߓ�
       ,XDC.consumption_tax_classe     --����ŋ敪
       ,FLV03.meaning                  --����ŋ敪��
       ,XDC.half_adjust_classe         --�l�̌ܓ��敪
       ,FLV04.meaning                  --�l�̌ܓ��敪��
       ,XDC.payments_judgment_classe   --�x�����f�敪
       ,FLV05.meaning                  --�x�����f�敪��
       ,XDC.billing_code               --������R�[�h
       ,XLCV.location_name             --�����於
       ,XDC.billing_standard           --�����
       ,FLV06.meaning                  --�������
       ,XDC.small_weight               --�����d��
       ,XDC.pay_picking_amount         --�x���s�b�L���O�P��
       ,XDC.bill_picking_amount        --�����s�b�L���O�P��
       ,FU_CB.user_name                --�쐬��
       ,TO_CHAR( XDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�쐬��
       ,FU_LU.user_name                --�ŏI�X�V��
       ,TO_CHAR( XDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�ŏI�X�V��
       ,FU_LL.user_name                --�ŏI�X�V���O�C��
  FROM  xxwip_delivery_company  XDC    --�^���p�^���Ǝ҃A�h�I���}�X�^
       ,xxsky_carriers_v        XCRV   --�^���ƎҎ擾�pVIEW
       ,xxsky_locations_v       XLCV   --�����於�擾�pVIEW
       ,fnd_user                FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
       ,fnd_user                FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       ,fnd_user                FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
       ,fnd_logins              FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
       ,fnd_lookup_values       FLV01  --�N�C�b�N�R�[�h(���i�敪��)
       ,fnd_lookup_values       FLV02  --�N�C�b�N�R�[�h(�I�����C�����Ή��敪��)
       ,fnd_lookup_values       FLV03  --�N�C�b�N�R�[�h(����ŋ敪��)
       ,fnd_lookup_values       FLV04  --�N�C�b�N�R�[�h(�l�̌ܓ��敪��)
       ,fnd_lookup_values       FLV05  --�N�C�b�N�R�[�h(�x�����f�敪��)
       ,fnd_lookup_values       FLV06  --�N�C�b�N�R�[�h(�������)
 WHERE  XDC.delivery_company_code = XCRV.freight_code(+)
   AND  XDC.billing_code          = XLCV.location_code(+)
   AND  XDC.created_by        = FU_CB.user_id(+)
   AND  XDC.last_updated_by   = FU_LU.user_id(+)
   AND  XDC.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id         = FU_LL.user_id(+)
   AND  FLV01.language(+)     = 'JA'
   AND  FLV01.lookup_type(+)  = 'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)  = XDC.goods_classe
   AND  FLV02.language(+)     = 'JA'
   AND  FLV02.lookup_type(+)  = 'XXWIP_ONLINE_TYPE'
   AND  FLV02.lookup_code(+)  = XDC.online_classe
   AND  FLV03.language(+)     = 'JA'
   AND  FLV03.lookup_type(+)  = 'XXWIP_FARETAX_TYPE'
   AND  FLV03.lookup_code(+)  = XDC.consumption_tax_classe
   AND  FLV04.language(+)     = 'JA'
   AND  FLV04.lookup_type(+)  = 'XXCMN_ROUND'
   AND  FLV04.lookup_code(+)  = XDC.half_adjust_classe
   AND  FLV05.language(+)     = 'JA'
   AND  FLV05.lookup_type(+)  = 'XXCMN_PAY_JUDGEMENT'
   AND  FLV05.lookup_code(+)  = XDC.payments_judgment_classe
   AND  FLV06.language(+)     = 'JA'
   AND  FLV06.lookup_type(+)  = 'XXWIP_CLAIM_PAY_STD'
   AND  FLV06.lookup_code(+)  = XDC.billing_standard
/

COMMENT ON TABLE APPS.XXSKY_�^���p�^���Ǝ�_��{_V IS 'SKYLINK�p�^���p�^���Ǝҁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�^���Ǝ҃R�[�h                 IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�^���ƎҖ�                     IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�K�p�J�n��                     IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�K�p�I����                     IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�I�����C�����Ή��敪           IS '�I�����C�����Ή��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�I�����C�����Ή��敪��         IS '�I�����C�����Ή��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�������ߓ�                     IS '�������ߓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.����ŋ敪                     IS '����ŋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.����ŋ敪��                   IS '����ŋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�l�̌ܓ��敪                   IS '�l�̌ܓ��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�l�̌ܓ��敪��                 IS '�l�̌ܓ��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�x�����f�敪                   IS '�x�����f�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�x�����f�敪��                 IS '�x�����f�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.������R�[�h                   IS '������R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�����於                       IS '�����於'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�����                       IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�������                     IS '�������'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�����d��                       IS '�����d��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�x���s�b�L���O�P��             IS '�x���s�b�L���O�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�����s�b�L���O�P��             IS '�����s�b�L���O�P��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���p�^���Ǝ�_��{_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
