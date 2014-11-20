CREATE OR REPLACE VIEW APPS.XXSKY_�^���}�X�^KI_����_V
(
 �x�������敪
,�x�������敪��
,���i�敪
,���i�敪��
,�^���Ǝ�
,�^���ƎҖ�
,�z���敪
,�z���敪��
,�^������
,�d��
,�K�p�J�n��
,�K�p�I����
,�^����
,���[�t���ڊ���
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  
        XDC.p_b_classe                 --�x�������敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                  --�x�������敪��
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01  --�N�C�b�N�R�[�h(�x�������敪��)
         WHERE FLV01.language    = 'JA'
           AND FLV01.lookup_type = 'XXWIP_PAYCHARGE_TYPE'
           AND FLV01.lookup_code = XDC.p_b_classe
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDC.goods_classe               --���i�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                  --���i�敪��
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02  --�N�C�b�N�R�[�h(���i�敪��)
         WHERE FLV02.language    = 'JA'
           AND FLV02.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV02.lookup_code = XDC.goods_classe
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDC.delivery_company_code      --�^���Ǝ҃R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XCRV.party_name                --�^���ƎҖ�
       ,(SELECT XCRV.party_name
         FROM xxsky_carriers_v XCRV   --�^���Ǝҏ��VIEW
         WHERE XDC.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDC.shipping_address_classe    --�z���敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV03.meaning                  --�z���敪��
       ,(SELECT FLV03.meaning
         FROM fnd_lookup_values FLV03  --�N�C�b�N�R�[�h(�z���敪��)
         WHERE FLV03.language    = 'JA'
           AND FLV03.lookup_type = 'XXCMN_SHIP_METHOD'
           AND FLV03.lookup_code = XDC.shipping_address_classe
        ) FLV03_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDC.delivery_distance          --�^������
       ,XDC.delivery_weight            --�d��
       ,XDC.start_date_active          --�K�p�J�n��
       ,XDC.end_date_active            --�K�p�I����
       ,XDC.shipping_expenses          --�^����
       ,XDC.leaf_consolid_add          --���[�t���ڊ���
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XDC.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XDC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XDC.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XDC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                       --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
              ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XDC.last_update_login = FL_LL.login_id
         AND   FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxwip_delivery_charges  XDC    --�^���A�h�I���}�X�^�C���^�t�F�[�X
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_carriers_v        XCRV   --�^���Ǝҏ��VIEW
       --,fnd_user                FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins              FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
       --,fnd_lookup_values       FLV01  --�N�C�b�N�R�[�h(�x�������敪��)
       --,fnd_lookup_values       FLV02  --�N�C�b�N�R�[�h(���i�敪��)
       --,fnd_lookup_values       FLV03  --�N�C�b�N�R�[�h(�z���敪��)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
 WHERE  XDC.start_date_active <= TRUNC(SYSDATE)
   AND  XDC.end_date_active   >= TRUNC(SYSDATE)
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  XDC.delivery_company_code = XCRV.freight_code(+)
   --AND  XDC.created_by        = FU_CB.user_id(+)
   --AND  XDC.last_updated_by   = FU_LU.user_id(+)
   --AND  XDC.last_update_login = FL_LL.login_id(+)
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
   AND  XDC.p_b_classe        = '2'
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language(+)    = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXWIP_PAYCHARGE_TYPE'
   --AND  FLV01.lookup_code(+) = XDC.p_b_classe
   --AND  FLV02.language(+)    = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   --AND  FLV02.lookup_code(+) = XDC.goods_classe
   --AND  FLV03.language(+)    = 'JA'
   --AND  FLV03.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   --AND  FLV03.lookup_code(+) = XDC.shipping_address_classe
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKY_�^���}�X�^KI_����_V IS 'SKYLINK�p�^���}�X�^�i���݁jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�x�������敪                IS '�x�������敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�x�������敪��              IS '�x�������敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.���i�敪                    IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.���i�敪��                  IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�^���Ǝ�                    IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�^���ƎҖ�                  IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�z���敪                    IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�z���敪��                  IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�^������                    IS '�^������'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�d��                        IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�K�p�J�n��                  IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�K�p�I����                  IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�^����                      IS '�^����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.���[�t���ڊ���              IS '���[�t���ڊ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�쐬��                      IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�쐬��                      IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�ŏI�X�V��                  IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�ŏI�X�V��                  IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���}�X�^KI_����_V.�ŏI�X�V���O�C��            IS '�ŏI�X�V���O�C��'
/
