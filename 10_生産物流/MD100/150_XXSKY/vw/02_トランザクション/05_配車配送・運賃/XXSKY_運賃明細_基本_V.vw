CREATE OR REPLACE VIEW APPS.XXSKY_�^������_��{_V
(
 �˗�NO
,�����NO
,�z��NO
,�^���Ǝ�
,�^���ƎҖ�
,�o�ɑq�ɃR�[�h
,�o�ɑq�ɖ�
,�z���敪
,�z���敪��
,�z����R�[�h�敪
,�z����R�[�h�敪��
,�z����R�[�h
,��\�z���於
,�x�����f�敪
,�x�����f�敪��
,�Ǌ����_
,�Ǌ����_����
,�o�ɓ�
,������
,�񍐓�
,���f��
,���i�敪
,���i�敪��
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,����
,���ۋ���
,��
,�d��
,�^�C�v
,�^�C�v��
,���ڋ敪
,���ڋ敪��
,�_��O�敪
,�_��O�敪��
,�U�֐�
,�U�֐於
,�E�v
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
         XDL.request_no                         -- �˗�No
        ,XDL.invoice_no                         -- �����No
        ,XDL.delivery_no                        -- �z��No
        ,XDL.delivery_company_code              -- �^���Ǝ�
        ,XC2V.party_name                        -- �^���ƎҖ�
        ,XDL.whs_code                           -- �o�ɑq�ɃR�[�h
        ,XILV.description                       -- �o�ɑq�ɖ�
        ,XDL.dellivary_classe                   -- �z���敪
        ,FLV01.meaning                          -- �z���敪��
        ,XDL.code_division                      -- �z����R�[�h�敪
        ,FLV02.meaning                          -- �z����R�[�h�敪��
        ,XDL.shipping_address_code              -- �z����R�[�h
        ,SAC.name    shipping_address_code_name -- ��\�z���於
        ,XDL.payments_judgment_classe           -- �x�����f�敪
        ,FLV03.meaning                          -- �x�����f�敪��
        ,CASE WHEN XDL.order_type = '1'
-- 2009/12/01 Y.Fukami Mod Start
--              THEN XHMV.�z����_���_�R�[�h       -- �Ǌ����_�i�o�ׂ̏ꍇ�j
              THEN XHM2V.�z����_���_�R�[�h      -- �Ǌ����_�i�o�ׂ̏ꍇ�j
-- 2009/12/01 Y.Fukami Mod End
              WHEN XDL.order_type = '2'
              THEN NULL                         -- �Ǌ����_�i�x���̏ꍇ�ANULL�j
              WHEN XDL.order_type = '3'
              THEN '2100'                       -- �Ǌ����_�i�ړ��̏ꍇ�A'2100'�Œ�j
         END base_code
        ,CASE WHEN XDL.order_type = '1'
-- 2009/12/01 Y.Fukami Mod Start
--              THEN XHMV.�z����_���_��           -- �Ǌ����_���́i�o�ׂ̏ꍇ�j
              THEN XHM2V.�z����_���_��          -- �Ǌ����_���́i�o�ׂ̏ꍇ�j
-- 2009/12/01 Y.Fukami Mod End
              WHEN XDL.order_type = '2'
              THEN NULL                         -- �Ǌ����_���́i�x���̏ꍇ�ANULL�j
              WHEN XDL.order_type = '3'
              THEN XL2V02.location_name         -- �Ǌ����_���́i�ړ��̏ꍇ�A'������'�j
         END base_name
        ,XDL.ship_date                          -- �o�ɓ�
        ,XDL.arrival_date                       -- ������
        ,XDL.report_date                        -- �񍐓�
        ,XDL.judgement_date                     -- ���f��
        ,XDL.goods_classe                       -- ���i�敪
        ,FLV04.meaning                          -- ���i�敪��
        ,XDL.weight_capacity_class              -- �d�ʗe�ϋ敪
        ,FLV05.meaning                          -- �d�ʗe�ϋ敪��
        ,XDL.distance                           -- ����
        ,XDL.actual_distance                    -- ���ۋ���
        ,XDL.qty                                -- ��
        ,XDL.delivery_weight                    -- �d��
        ,XDL.order_type                         -- �^�C�v
        ,FLV06.meaning                          -- �^�C�v��
        ,XDL.mixed_code                         -- ���ڋ敪
        ,FLV07.meaning                          -- ���ڋ敪��
        ,XDL.outside_contract                   -- �_��O�敪
        ,FLV08.meaning                          -- �_��O�敪��
        ,XDL.transfer_location                  -- �U�֐�
        ,XL2V.location_name                     -- �U�֐於
        ,XDL.description                        -- �E�v
        ,FU_CB.user_name                        -- �쐬��
        ,TO_CHAR( XDL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                -- �쐬��(�x���˗����IF����)
        ,FU_LU.user_name                        -- �ŏI�X�V��
        ,TO_CHAR( XDL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                -- �ŏI�X�V��(�x���˗����IF����)
        ,FU_LL.user_name                        -- �ŏI�X�V���O�C��
FROM
-- 2009/12/01 Y.Fukami Mod Start
--         xxwip_delivery_lines   XDL             -- �^�����׃A�h�I��
-- �^�����׃A�h�I���ɏo�ׂ̏ꍇ�̊Ǌ����_���擾���邽�߂̔z����ID���󒍃w�b�_�A�h�I�����猋��
        (
                SELECT
                       XXDL.request_no
                      ,XXDL.invoice_no
                      ,XXDL.delivery_no
                      ,XXDL.delivery_company_code
                      ,XXDL.whs_code
                      ,XXDL.dellivary_classe
                      ,XXDL.code_division
                      ,XXDL.shipping_address_code
                      ,XXDL.payments_judgment_classe
                      ,XXDL.ship_date
                      ,XXDL.arrival_date
                      ,XXDL.report_date
                      ,XXDL.judgement_date
                      ,XXDL.goods_classe
                      ,XXDL.weight_capacity_class
                      ,XXDL.distance
                      ,XXDL.actual_distance
                      ,XXDL.qty
                      ,XXDL.delivery_weight
                      ,XXDL.order_type
                      ,XXDL.mixed_code
                      ,XXDL.outside_contract
                      ,XXDL.transfer_location
                      ,XXDL.description
                      ,XXDL.created_by
                      ,XXDL.creation_date
                      ,XXDL.last_update_login
                      ,XXDL.last_updated_by
                      ,XXDL.last_update_date
                      ,XOHA.result_deliver_to_id
                FROM
                       xxwip_delivery_lines     XXDL      -- �^�����׃A�h�I��
                      ,xxwsh_order_headers_all  XOHA      -- �󒍃w�b�_�A�h�I��
                WHERE
                       XOHA.request_no(+)              =  XXDL.request_no
                  AND  XOHA.latest_external_flag(+)    =  'Y'
        )                                       XDL     -- �^�����׃A�h�I���{�󒍃w�b�_�A�h�I���̔z����ID
-- 2009/12/01 Y.Fukami Mod End
        ,xxsky_carriers2_v      XC2V            -- SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
        ,xxsky_item_locations_v XILV            -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�ɑq�ɖ�)
        ,xxsky_locations2_v     XL2V            -- SKYLINK�p����VIEW ���Ə����VIEW2(�U�֐於)
        ,fnd_lookup_values      FLV01           -- �N�C�b�N�R�[�h�\(�z���敪��)
        ,fnd_lookup_values      FLV02           -- �N�C�b�N�R�[�h�\(�z����R�[�h�敪��)
        ,fnd_lookup_values      FLV03           -- �N�C�b�N�R�[�h�\(�x�����f�敪��)
-- 2009/12/01 Y.Fukami Mod Start
--        ,XXSKY_�z����}�X�^_��{_V    XHMV      -- SKYLINK�p�z����}�X�^_��{_V
        ,XXSKY_�z����}�X�^_��{2_V   XHM2V     -- SKYLINK�p�z����}�X�^_��{2_V
-- 2009/12/01 Y.Fukami Mod End
        ,xxsky_locations2_v     XL2V02          -- SKYLINK�p����VIEW ���Ə����VIEW2(�Ǌ����_��)
        ,fnd_lookup_values      FLV04           -- �N�C�b�N�R�[�h�\(���i�敪��)
        ,fnd_lookup_values      FLV05           -- �N�C�b�N�R�[�h�\(�d�ʗe�ϋ敪��)
        ,fnd_lookup_values      FLV06           -- �N�C�b�N�R�[�h�\(�^�C�v��)
        ,fnd_lookup_values      FLV07           -- �N�C�b�N�R�[�h�\(���ڋ敪��)
        ,fnd_lookup_values      FLV08           -- �N�C�b�N�R�[�h�\(�_��O�敪��)
        ,( -- ��\�z���於�擾�p�i�R�[�h�敪�̒l�ɂ���Ď擾�悪�قȂ�j
                -- �R�[�h�敪��'1:�q��'�̏ꍇ��OPM�ۊǑq�ɖ����擾
                SELECT
                        1                       class   -- 1:�q��
                        , segment1              code    -- �ۊǑq��No
                        , description           name    -- �ۊǑq�ɖ�
                        , date_from             dstart  -- �K�p�J�n��
                        , date_to               dend    -- �K�p�I����
                FROM
                        xxsky_item_locations_v          -- �ۊǑq��
                UNION ALL
                -- �R�[�h�敪��'2:�����'�̏ꍇ�͎����T�C�g�����擾
                SELECT
                        2                       class   -- 2:�����
                        , vendor_site_code      code    -- �����T�C�gNo
                        , vendor_site_name      name    -- �����T�C�g��
                        , start_date_active     dstart  -- �K�p�J�n��
                        , end_date_active       dend    -- �K�p�I����
                FROM
                        xxsky_vendor_sites2_v           -- �d����T�C�gVIEW
                UNION ALL
                -- �R�[�h�敪��'3:�z����'�̏ꍇ�͔z���於���擾
                SELECT
                        3                       class   -- 3:�z����
                        , party_site_number     code    -- �z����No
                        , party_site_name       name    -- �z���於
                        , start_date_active     dstart  -- �K�p�J�n��
                        , end_date_active       dend    -- �K�p�I����
                FROM
                        xxsky_party_sites2_v            -- �z����VIEW
        )                                       SAC     -- �z���於�擾�p
        ,fnd_user                               FU_CB   -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                               FU_LU   -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                               FU_LL   -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                             FL_LL   -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        -- �^���ƎҖ�
        XC2V.freight_code(+)            =  XDL.delivery_company_code
   AND  XC2V.start_date_active(+)       <= XDL.ship_date
   AND  XC2V.end_date_active(+)         >= XDL.ship_date
        -- �o�ɑq�ɖ�
   AND  XILV.segment1(+)                = XDL.whs_code
        -- �z���敪��
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV01.lookup_code(+)            = XDL.dellivary_classe
        -- �z����R�[�h�敪��
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWIP_CODE_TYPE'
   AND  FLV02.lookup_code(+)            = XDL.code_division
        -- ��\�z���於
   AND  XDL.code_division               = SAC.class(+)
   AND  XDL.shipping_address_code       = SAC.code(+)
   AND  SAC.dstart(+)                   <= XDL.ship_date
   AND  SAC.dend(+)                     >= XDL.ship_date
        -- �x���攻�f�敪��
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXWIP_CLAIM_PAY_STD'
   AND  FLV03.lookup_code(+)            = XDL.payments_judgment_classe
        -- �Ǌ����_���擾
-- 2009/12/01 Y.Fukami Mod Start
--   AND  XDL.shipping_address_code       = XHMV.�z����_�ԍ�(+)
   AND  XDL.result_deliver_to_id        = XHM2V.�z����_ID(+)
   AND  XHM2V.�ڋq���__�K�p�J�n��(+)   <= XDL.ship_date
   AND  XHM2V.�ڋq���__�K�p�I����(+)   >= XDL.ship_date
   AND  XHM2V.�z����_�K�p�J�n��(+)     <= XDL.ship_date
   AND  XHM2V.�z����_�K�p�I����(+)     >= XDL.ship_date
-- 2009/12/01 Y.Fukami Mod End
        -- �Ǌ����_��
   AND  XL2V02.location_code(+)         = '2100'            -- ������
   AND  XL2V02.start_date_active(+)    <= XDL.ship_date
   AND  XL2V02.end_date_active(+)      >= XDL.ship_date
        -- ���i�敪��
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXWIP_ITEM_TYPE'
   AND  FLV04.lookup_code(+)            = XDL.goods_classe
        -- �d�ʗe�ϋ敪��
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV05.lookup_code(+)            = XDL.weight_capacity_class
        -- �^�C�v��
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXWIP_ORDER_TYPE'
   AND  FLV06.lookup_code(+)            = XDL.order_type
        -- ���ڋ敪��
   AND  FLV07.language(+)               = 'JA'
   AND  FLV07.lookup_type(+)            = 'XXCMN_D24'
   AND  FLV07.lookup_code(+)            = XDL.mixed_code
        -- �_��O�敪��
   AND  FLV08.language(+)               = 'JA'
   AND  FLV08.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV08.lookup_code(+)            = XDL.outside_contract
        -- �U�֐於
   AND  XL2V.location_code(+)           = XDL.transfer_location
   AND  XL2V.start_date_active(+)       <= XDL.ship_date
   AND  XL2V.end_date_active(+)         >= XDL.ship_date
        -- ���[�U���Ȃ�
   AND  XDL.created_by                  = FU_CB.user_id(+)
   AND  XDL.last_updated_by             = FU_LU.user_id(+)
   AND  XDL.last_update_login           = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�^������_��{_V IS 'SKYLINK�p�^�����ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�˗�NO IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�����NO IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�z��NO IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�^���Ǝ� IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�^���ƎҖ� IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�o�ɑq�ɃR�[�h IS '�o�ɑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�o�ɑq�ɖ� IS '�o�ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�z���敪 IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�z���敪�� IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�z����R�[�h�敪 IS '�z����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�z����R�[�h�敪�� IS '�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�z����R�[�h IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.��\�z���於 IS '��\�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�x�����f�敪 IS '�x�����f�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�x�����f�敪�� IS '�x�����f�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�Ǌ����_ IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�Ǌ����_���� IS '�Ǌ����_����'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�o�ɓ� IS '�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�񍐓� IS '�񍐓�'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���f�� IS '���f��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�d�ʗe�ϋ敪 IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�d�ʗe�ϋ敪�� IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���ۋ��� IS '���ۋ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�� IS '��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�^�C�v IS '�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�^�C�v�� IS '�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���ڋ敪 IS '���ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.���ڋ敪�� IS '���ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�_��O�敪 IS '�_��O�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�_��O�敪�� IS '�_��O�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�U�֐� IS '�U�֐�'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�U�֐於 IS '�U�֐於'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�E�v IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^������_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
