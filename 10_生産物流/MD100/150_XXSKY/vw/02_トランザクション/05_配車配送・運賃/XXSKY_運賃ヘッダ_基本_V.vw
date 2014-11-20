CREATE OR REPLACE VIEW APPS.XXSKY_�^���w�b�__��{_V
(
�^���Ǝ�
,�^���ƎҖ�
,�z��NO
,�����NO
,�����NO�Q
,�x�������敪
,�x�������敪��
,�x�����f�敪
,�x�����f�敪��
,�o�ɓ�
,������
,�񍐓�
,���f��
,���i�敪
,���i�敪��
,���ڋ敪
,���ڋ敪��
,�����^��
,�_��^��
,���z
,���v
,������
,�Œ�����
,�z���敪
,�z���敪��
,��\�o�ɑq�ɃR�[�h
,��\�o�ɑq�ɖ�
,��\�z����R�[�h�敪
,��\�z����R�[�h�敪��
,��\�z����R�[�h
,��\�z���於
,���P
,���Q
,�d�ʂP
,�d�ʂQ
,���ڊ������z
,�Œ����ۋ���
,�ʍs��
,�s�b�L���O��
,���ڐ�
,��\�^�C�v
,��\�^�C�v��
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,�_��O�敪
,�_��O�敪��
,���ً敪
,���ً敪��
,�x���m��敪
,�x���m��敪��
,�x���m���
,�x���m��ߖ�
,�U�֐�
,�U�֐於
,�O���ƎҕύX��
,�^���E�v
,�z�ԃ^�C�v
,�z�ԃ^�C�v��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
         XD.delivery_company_code               -- �^���Ǝ�
        ,XC2V.party_name                        -- �^���ƎҖ�
        ,XD.delivery_no                         -- �z��No
        ,XD.invoice_no                          -- �����No
        ,XD.invoice_no2                         -- �����No2
        ,XD.p_b_classe                          -- �x�������敪
        ,FLV01.meaning                          -- �x�������敪��
        ,XD.payments_judgment_classe            -- �x�����f�敪
        ,FLV02.meaning                          -- �x�����f�敪��
        ,XD.ship_date                           -- �o�ɓ�
        ,XD.arrival_date                        -- ������
        ,XD.report_date                         -- �񍐓�
        ,XD.judgement_date                      -- ���f��
        ,XD.goods_classe                        -- ���i�敪
        ,FLV03.meaning                          -- ���i�敪��
        ,XD.mixed_code                          -- ���ڋ敪
        ,FLV04.meaning                          -- ���ڋ敪��
        ,XD.charged_amount                      -- �����^��
        ,XD.contract_rate                       -- �_��^��
        ,XD.balance                             -- ���z
        ,XD.total_amount                        -- ���v
        ,XD.many_rate                           -- ������
        ,XD.distance                            -- �Œ�����
        ,XD.delivery_classe                     -- �z���敪
        ,FLV05.meaning                          -- �z���敪��
        ,XD.whs_code                            -- ��\�o�ɑq�ɃR�[�h
        ,XILV.description                       -- ��\�o�ɑq�ɖ�
        ,XD.code_division                       -- ��\�z����R�[�h�敪
        ,FLV06.meaning                          -- ��\�z����R�[�h�敪��
        ,XD.shipping_address_code               -- ��\�z����R�[�h
        ,SAC.name       shipping_address_code_name -- ��\�z���於
        ,XD.qty1                                -- ��1
        ,XD.qty2                                -- ��2
        ,XD.delivery_weight1                    -- �d��1
        ,XD.delivery_weight2                    -- �d��2
        ,XD.consolid_surcharge                  -- ���ڊ������z
        ,XD.actual_distance                     -- �Œ����ۋ���
        ,XD.congestion_charge                   -- �ʍs��
        ,XD.picking_charge                      -- �s�b�L���O��
        ,XD.consolid_qty                        -- ���ڐ�
        ,XD.order_type                          -- ��\�^�C�v
        ,FLV07.meaning                          -- ��\�^�C�v��
        ,XD.weight_capacity_class               -- �d�ʗe�ϋ敪
        ,FLV08.meaning                          -- �d�ʗe�ϋ敪��
        ,XD.outside_contract                    -- �_��O�敪
        ,FLV09.meaning                          -- �_��O�敪��
        ,XD.output_flag                         -- ���ً敪
        ,CASE XD.output_flag                    -- ���ً敪��
                WHEN 'Y' THEN '���ق���'
                WHEN 'N' THEN '���قȂ�'
        END output_flag_name
        ,XD.defined_flag                        -- �x���m��敪
        ,CASE XD.defined_flag                   -- �x���m��敪��
                WHEN 'Y' THEN '�x���m��'
                WHEN 'N' THEN '�x�����m��'
        END defined_flag_name
        ,XD.return_flag                         -- �x���m���
        ,CASE XD.defined_flag                   -- �x���m��ߖ�
                WHEN 'Y' THEN '�x���m���߂�'
                WHEN 'N' THEN '�x���m���߂��Ȃ�'
        END return_flag_name
        ,XD.transfer_location                   -- �U�֐�
        ,XL2V.location_name                     -- �U�֐於
        ,XD.outside_up_count                    -- �O���ƎҕύX��
        ,XD.description                         -- �^���E�v
        ,XD.dispatch_type                       -- �z�ԃ^�C�v
        ,CASE XD.dispatch_type                  -- �z�ԃ^�C�v��
                WHEN '1' THEN '�ʏ�z��'
                WHEN '2' THEN '�`�[�Ȃ��z��(���[�t����)'
                WHEN '3' THEN '�`�[�Ȃ��z��(���[�t�����ȊO)'
        END dispatch_type_name
        ,FU_CB.user_name                        -- �쐬��
        ,TO_CHAR( XD.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                -- �쐬��(�x���˗����IF����)
        ,FU_LU.user_name                        -- �ŏI�X�V��
        ,TO_CHAR( XD.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                -- �ŏI�X�V��(�x���˗����IF����)
        ,FU_LL.user_name                        -- �ŏI�X�V���O�C��
FROM
         xxwip_deliverys        XD              -- �^���w�b�_�[�A�h�I��
        ,xxsky_carriers2_v      XC2V            -- SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
        ,xxsky_item_locations_v XILV            -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(��\�o�ɑq�ɖ�)
        ,xxsky_locations2_v     XL2V            -- SKYLINK�p����VIEW ���Ə����VIEW2(�U�֐於)
        ,fnd_lookup_values      FLV01           -- �N�C�b�N�R�[�h�\(�x�������敪��)
        ,fnd_lookup_values      FLV02           -- �N�C�b�N�R�[�h�\(�x�����f�敪��)
        ,fnd_lookup_values      FLV03           -- �N�C�b�N�R�[�h�\(���i�敪��)
        ,fnd_lookup_values      FLV04           -- �N�C�b�N�R�[�h�\(���ڋ敪��)
        ,fnd_lookup_values      FLV05           -- �N�C�b�N�R�[�h�\(�z���敪��)
        ,fnd_lookup_values      FLV06           -- �N�C�b�N�R�[�h�\(��\�z����R�[�h�敪��)
        ,fnd_lookup_values      FLV07           -- �N�C�b�N�R�[�h�\(��\�^�C�v��)
        ,fnd_lookup_values      FLV08           -- �N�C�b�N�R�[�h�\(�d�ʗe�ϋ敪��)
        ,fnd_lookup_values      FLV09           -- �N�C�b�N�R�[�h�\(�_��O�敪��)
        ,( -- �z���於�擾�p�i�R�[�h�敪�̒l�ɂ���Ď擾�悪�قȂ�j
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
        )                       SAC                     -- �z���於�擾�p
        ,fnd_user               FU_CB                   -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user               FU_LU                   -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user               FU_LL                   -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins             FL_LL                   -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
        -- �^���ƎҖ�
        XC2V.freight_code(+)            = XD.delivery_company_code
   AND  XC2V.start_date_active(+)       <= XD.ship_date
   AND  XC2V.end_date_active(+)         >= XD.ship_date
        -- �x�������敪��
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWIP_PAYCHARGE_TYPE'
   AND  FLV01.lookup_code(+)            = XD.p_b_classe
        -- �x���攻�f�敪��
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWIP_CLAIM_PAY_STD'
   AND  FLV02.lookup_code(+)            = XD.payments_judgment_classe
        -- ���i�敪��
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXWIP_ITEM_TYPE'
   AND  FLV03.lookup_code(+)            = XD.goods_classe
        -- ���ڋ敪��
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXCMN_D24'
   AND  FLV04.lookup_code(+)            = XD.mixed_code
        -- �z���敪��
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV05.lookup_code(+)            = XD.delivery_classe
        -- ��\�o�ɑq�ɖ�
   AND  XILV.segment1(+)                = XD.whs_code
        -- ��\�z����R�[�h�敪��
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXWIP_CODE_TYPE'
   AND  FLV06.lookup_code(+)            = XD.code_division
        -- ��\�z���於
   AND  XD.code_division                = SAC.class(+)
   AND  XD.shipping_address_code        = SAC.code(+)
   AND  SAC.dstart(+)                   <= XD.ship_date
   AND  SAC.dend(+)                     >= XD.ship_date
        -- ��\�^�C�v��
   AND  FLV07.language(+)               = 'JA'
   AND  FLV07.lookup_type(+)            = 'XXWIP_ORDER_TYPE'
   AND  FLV07.lookup_code(+)            = XD.order_type
        -- �d�ʗe�ϋ敪��
   AND  FLV08.language(+)               = 'JA'
   AND  FLV08.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV08.lookup_code(+)            = XD.weight_capacity_class
        -- �_��O�敪��
   AND  FLV09.language(+)               = 'JA'
   AND  FLV09.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV09.lookup_code(+)            = XD.outside_contract
        -- �U�֐於
   AND  XL2V.location_code(+)           = XD.transfer_location
   AND  XL2V.start_date_active(+)       <= XD.ship_date
   AND  XL2V.end_date_active(+)         >= XD.ship_date
        -- ���[�U���Ȃ�
   AND  XD.created_by                   = FU_CB.user_id(+)
   AND  XD.last_updated_by              = FU_LU.user_id(+)
   AND  XD.last_update_login            = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�^���w�b�__��{_V IS 'SKYLINK�p�^���w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�^���Ǝ�             IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�^���ƎҖ�           IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�z��NO               IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�����NO             IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�����NO�Q           IS '�����No2'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x�������敪         IS '�x�������敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x�������敪��       IS '�x�������敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x�����f�敪         IS '�x�����f�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x�����f�敪��       IS '�x�����f�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�o�ɓ�               IS '�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�񍐓�               IS '�񍐓�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���f��               IS '���f��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���i�敪             IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���i�敪��           IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���ڋ敪             IS '���ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���ڋ敪��           IS '���ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�����^��             IS '�����^��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�_��^��             IS '�_��^��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���z                 IS '���z'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���v                 IS '���v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.������               IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�Œ�����             IS '�Œ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�z���敪             IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�z���敪��           IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�o�ɑq�ɃR�[�h   IS '��\�o�ɑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�o�ɑq�ɖ�       IS '��\�o�ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�z����R�[�h�敪     IS '��\�z����R�[�h��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�z����R�[�h�敪��   IS '��\�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�z����R�[�h     IS '��\�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�z���於         IS '��\�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���P               IS '���P'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���Q               IS '���Q'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�d�ʂP               IS '�d�ʂP'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�d�ʂQ               IS '�d�ʂQ'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���ڊ������z         IS '���ڊ������z'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�Œ����ۋ���         IS '�Œ����ۋ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�ʍs��               IS '�ʍs��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�s�b�L���O��         IS '�s�b�L���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���ڐ�               IS '���ڐ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�^�C�v           IS '��\�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.��\�^�C�v��         IS '��\�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�d�ʗe�ϋ敪         IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�d�ʗe�ϋ敪��       IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�_��O�敪           IS '�_��O�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�_��O�敪��         IS '�_��O�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���ً敪             IS '���ً敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.���ً敪��           IS '���ً敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x���m��敪         IS '�x���m��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x���m��敪��       IS '�x���m��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x���m���           IS '�x���m���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�x���m��ߖ�         IS '�x���m��ߖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�U�֐�               IS '�U�֐�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�U�֐於             IS '�U�֐於'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�O���ƎҕύX��     IS '�O���ƎҕύX��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�^���E�v             IS '�^���E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�z�ԃ^�C�v           IS '�z�ԃ^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�z�ԃ^�C�v��         IS '�z�ԃ^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�쐬��               IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�ŏI�X�V��           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���w�b�__��{_V.�ŏI�X�V���O�C��     IS '�ŏI�X�V���O�C��'
/
