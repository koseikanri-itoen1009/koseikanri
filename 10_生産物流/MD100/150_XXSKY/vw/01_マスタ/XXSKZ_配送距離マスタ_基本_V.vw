/*************************************************************************
 * 
 * View  Name      : XXSKZ_�z�������}�X�^_��{_V
 * Description     : XXSKZ_�z�������}�X�^_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/22    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�z�������}�X�^_��{_V
(
 ���i�敪
,���i�敪��
,�^���Ǝ҃R�[�h
,�^���ƎҖ�
,�o�ɑq��
,�o�ɑq�ɖ�
,�R�[�h�敪
,�R�[�h�敪��
,�z����R�[�h
,�z���於
,�K�p�J�n��
,�K�p�I����
,�ԗ�����
,��������
,���ڊ�������
,���ۋ���
,�G���AA
,�G���AB
,�G���AC
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XDD.goods_classe                 --���i�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV01.meaning                    --���i�敪��
       ,(SELECT FLV01.meaning
         FROM fnd_lookup_values FLV01    --�N�C�b�N�R�[�h(���i�敪��)
         WHERE FLV01.language = 'JA'
           AND FLV01.lookup_type = 'XXWIP_ITEM_TYPE'
           AND FLV01.lookup_code = XDD.GOODS_CLASSE
        ) FLV01_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDD.delivery_company_code        --�^���Ǝ҃R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XCRV.party_name                  --�^���ƎҖ�
       ,(SELECT XCRV.party_name
         FROM xxskz_carriers_v XCRV   --�^���Ǝҏ��VIEW
         WHERE XDD.delivery_company_code = XCRV.freight_code
        ) XCRV_party_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDD.origin_shipment              --�o�ɑq��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,XILV.description                 --�o�ɑq�ɖ�
       ,(SELECT XILV.description
         FROM xxskz_item_locations_v XILV   --OPM�ۊǏꏊ���VIEW
         WHERE XDD.origin_shipment =  XILV.segment1
        ) XILV_description
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDD.code_division                --�R�[�h�敪
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FLV02.meaning                    --�R�[�h�敪��
       ,(SELECT FLV02.meaning
         FROM fnd_lookup_values FLV02    --�N�C�b�N�R�[�h(�R�[�h�敪��)
         WHERE FLV02.language = 'JA'
           AND FLV02.lookup_type = 'XXWIP_CODE_TYPE'
           AND FLV02.lookup_code = XDD.CODE_DIVISION
        ) FLV02_meaning
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDD.shipping_address_code        --�z����R�[�h
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,SAC.name    shipping_address_code_name    --�z���於
       ,CASE 
          --�R�[�h�敪��'1:�q��'�̏ꍇ��OPM�ۊǑq�ɖ����擾
          WHEN XDD.code_division = 1 THEN
            (SELECT description           --�ۊǑq�ɖ�
             FROM xxskz_item_locations_v  --�ۊǑq��
             WHERE segment1 = XDD.shipping_address_code)
          --�R�[�h�敪��'2:�����'�̏ꍇ�͎����T�C�g�����擾
          WHEN XDD.code_division = 2 THEN
            (SELECT vendor_site_name      --�����T�C�g��
             FROM xxskz_vendor_sites_v    --�d����T�C�gVIEW
             WHERE vendor_site_code = XDD.shipping_address_code)
          --�R�[�h�敪��'3:�z����'�̏ꍇ�͔z���於���擾
          WHEN XDD.code_division = 3 THEN
            (SELECT party_site_name       --�z���於
             FROM xxskz_party_sites_v     --�z����VIEW
             WHERE party_site_number = XDD.shipping_address_code)
          ELSE NULL
        END shipping_address_code_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,XDD.start_date_active            --�K�p�J�n��
       ,XDD.end_date_active              --�K�p�I����
       ,XDD.post_distance                --�ԗ�����
       ,XDD.small_distance               --��������
       ,XDD.consolid_add_distance        --���ڊ�������
       ,XDD.actual_distance              --���ۋ���
       ,XDD.area_a                       --�G���AA
       ,XDD.area_b                       --�G���AB
       ,XDD.area_c                       --�G���AC
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_CB.user_name                  --�쐬��
       ,(SELECT FU_CB.user_name
         FROM fnd_user FU_CB  --���[�U�[�}�X�^(created_by���̎擾�p)
         WHERE XDD.created_by = FU_CB.user_id
        ) FU_CB_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XDD.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�쐬��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LU.user_name                  --�ŏI�X�V��
       ,(SELECT FU_LU.user_name
         FROM fnd_user FU_LU  --���[�U�[�}�X�^(last_updated_by���̎擾�p)
         WHERE XDD.last_updated_by = FU_LU.user_id
        ) FU_LU_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
       ,TO_CHAR( XDD.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�ŏI�X�V��
-- 2010/01/28 T.Yoshimoto Mod Start �{�ғ�#1168
       --,FU_LL.user_name                  --�ŏI�X�V���O�C��
       ,(SELECT FU_LL.user_name
         FROM fnd_user    FU_LL  --���[�U�[�}�X�^(last_update_login���̎擾�p)
             ,fnd_logins FL_LL  --���O�C���}�X�^(last_update_login���̎擾�p)
         WHERE XDD.last_update_login = FL_LL.login_id
           AND FL_LL.user_id         = FU_LL.user_id
        ) FU_LL_user_name
-- 2010/01/28 T.Yoshimoto Mod End �{�ғ�#1168
  FROM  xxwip_delivery_distance   XDD    --�z�������A�h�I���}�X�^
-- 2010/01/28 T.Yoshimoto Del Start �{�ғ�#1168
       --,xxsky_carriers_v          XCRV   --�^���Ǝҏ��VIEW
       --,xxsky_item_locations_v    XILV   --OPM�ۊǏꏊ���VIEW
       --,(--�z���於�擾�p�i�R�[�h�敪�̒l�ɂ���Ď擾�悪�قȂ�j
       --     --�R�[�h�敪��'1:�q��'�̏ꍇ��OPM�ۊǑq�ɖ����擾
       --     SELECT 1                    class    --1:�q��
       --           ,segment1             code     --�ۊǑq��No
       --           ,description          name     --�ۊǑq�ɖ�
       --       FROM xxsky_item_locations_v  --�ۊǑq��
       --   UNION ALL
       --     --�R�[�h�敪��'2:�����'�̏ꍇ�͎����T�C�g�����擾
       --     SELECT 2                    class    --2:�����
       --           ,vendor_site_code     code     --�����T�C�gNo
       --           ,vendor_site_name     name     --�����T�C�g��
       --       FROM xxsky_vendor_sites_v  --�d����T�C�gVIEW
       --   UNION ALL
       --     --�R�[�h�敪��'3:�z����'�̏ꍇ�͔z���於���擾
       --     SELECT 3                    class    --3:�z����
       --           ,party_site_number    code     --�z����No
       --           ,party_site_name      name     --�z���於
       --       FROM xxsky_party_sites_v   --�z����VIEW
       -- )                       SAC      --�z���於�擾�p
       --,fnd_user                FU_CB    --���[�U�[�}�X�^(created_by���̎擾�p)
       --,fnd_user                FU_LU    --���[�U�[�}�X�^(last_updated_by���̎擾�p)
       --,fnd_user                FU_LL    --���[�U�[�}�X�^(last_update_login���̎擾�p)
       --,fnd_logins              FL_LL    --���O�C���}�X�^(last_update_login���̎擾�p)
       --,fnd_lookup_values       FLV01    --�N�C�b�N�R�[�h(���i�敪��)
       --,fnd_lookup_values       FLV02    --�N�C�b�N�R�[�h(�R�[�h�敪��)
 --WHERE  XDD.delivery_company_code = XCRV.freight_code(+)
   --AND  XDD.origin_shipment =  XILV.segment1(+)
   --AND  XDD.code_division = SAC.class(+)          --�z���於�擾�p
   --AND  XDD.shipping_address_code = SAC.code(+)   --�z���於�擾�p
   --AND  XDD.created_by        = FU_CB.user_id(+)
   --AND  XDD.last_updated_by   = FU_LU.user_id(+)
   --AND  XDD.last_update_login = FL_LL.login_id(+)
   --AND  FL_LL.user_id         = FU_LL.user_id(+)
   --AND  FLV01.language = 'JA'
   --AND  FLV01.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   --AND  FLV01.lookup_code(+) = XDD.GOODS_CLASSE
   --AND  FLV02.language = 'JA'
   --AND  FLV02.lookup_type(+) = 'XXWIP_CODE_TYPE'
   --AND  FLV02.lookup_code(+) = XDD.CODE_DIVISION
-- 2010/01/28 T.Yoshimoto Del End �{�ғ�#1168
/
COMMENT ON TABLE APPS.XXSKZ_�z�������}�X�^_��{_V IS 'SKYLINK�p�z�������}�X�^�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�^���Ǝ҃R�[�h   IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�^���ƎҖ�       IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�o�ɑq��         IS '�o�ɑq��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�o�ɑq�ɖ�       IS '�o�ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�R�[�h�敪       IS '�R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�R�[�h�敪��     IS '�R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�z����R�[�h     IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�z���於         IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�K�p�J�n��       IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�K�p�I����       IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�ԗ�����         IS '�ԗ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.��������         IS '��������'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.���ڊ�������     IS '���ڊ�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.���ۋ���         IS '���ۋ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�G���AA          IS '�G���AA'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�G���AB          IS '�G���AB'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�G���AC          IS '�G���AC'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�z�������}�X�^_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/