CREATE OR REPLACE VIEW APPS.XXSKY_�x���˗����IF_��{_V
(
��Ж�
,�f�[�^���
,�`���p�}��
,�����敪
,�����敪��
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,�˗������R�[�h
,�˗�������
,�w�������R�[�h
,�w��������
,�����R�[�h
,����於
,�z����R�[�h
,�z���於
,�o�ɑq�ɃR�[�h
,�o�ɑq�ɖ�
,�^���Ǝ҃R�[�h
,�^���ƎҖ�
,�o�ɓ�
,���ɓ�
,�^���敪
,�^���敪��
,����敪
,����敪��
,���׎���FROM
,���׎���FROM��
,���׎���TO
,���׎���TO��
,������
,�����i�ڃR�[�h
,�����i�ږ�
,�����i�ڗ���
,�����ԍ�
,�w�b�_�E�v
,���הԍ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�t��
,�˗�����
,���דE�v
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
         SUPREQ.corporation_name                        -- ��Ж�
        ,SUPREQ.data_class                              -- �f�[�^���
        ,SUPREQ.transfer_branch_no                      -- �`���p�}��
        ,SUPREQ.trans_type                              -- �����敪
        ,SUPREQ.trans_type_name                         -- �����敪��
        ,SUPREQ.weight_capacity_class                   -- �d�ʗe�ϋ敪
        ,FLV01.meaning                                  -- �d�ʗe�ϋ敪��
        ,SUPREQ.requested_department_code               -- �˗������R�[�h
        ,XL2V01.location_name                           -- �˗�������
        ,SUPREQ.instruction_post_code                   -- �w�������R�[�h
        ,XL2V02.location_name                           -- �w��������
        ,SUPREQ.vendor_code                             -- �����R�[�h
        ,XV2V.vendor_name                               -- ����於
        ,SUPREQ.ship_to_code                            -- �z����R�[�h
        ,XPS2V.party_site_name                          -- �z���於
        ,SUPREQ.shipped_locat_code                      -- �o�ɑq�ɃR�[�h
        ,XILV.description                               -- �o�ɑq�ɖ�
        ,SUPREQ.freight_carrier_code                    -- �^���Ǝ҃R�[�h
        ,XC2V.party_name                                -- �^���ƎҖ�
        ,SUPREQ.ship_date                               -- �o�ɓ�
        ,SUPREQ.arvl_date                               -- ���ɓ�
        ,SUPREQ.freight_charge_class                    -- �^���敪
        ,FLV02.meaning                                  -- �^���敪��
        ,SUPREQ.takeback_class                          -- ����敪
        ,FLV03.meaning                                  -- ����敪��
        ,SUPREQ.arrival_time_from                       -- ���׎���FROM
        ,FLV04.meaning                                  -- ���׎���FROM��
        ,SUPREQ.arrival_time_to                         -- ���׎���TO
        ,FLV05.meaning                                  -- ���׎���TO��
        ,SUPREQ.product_date                            -- ������
        ,SUPREQ.producted_item_code                     -- �����i�ڃR�[�h
        ,XIM2V01.item_name                              -- �����i�ږ�
        ,XIM2V01.item_short_name                        -- �����i�ڗ���
        ,SUPREQ.product_number                          -- �����ԍ�
        ,SUPREQ.header_description                      -- �w�b�_�E�v
        ,SUPREQ.line_number                             -- ���הԍ�(�x���˗����IF����)
        ,XPCV.prod_class_code                           -- ���i�敪
        ,XPCV.prod_class_name                           -- ���i�敪��
        ,XICV.item_class_code                           -- �i�ڋ敪
        ,XICV.item_class_name                           -- �i�ڋ敪��
        ,XCCV.crowd_code                                -- �Q�R�[�h
        ,SUPREQ.item_code                               -- �i�ڃR�[�h(�x���˗����IF����)
        ,XIM2V02.item_name                              -- �i�ږ�
        ,XIM2V02.item_short_name                        -- �i�ڗ���
        ,SUPREQ.futai_code                              -- �t��(�x���˗����IF����)
        ,SUPREQ.request_qty                             -- �˗�����(�x���˗����IF����)
        ,SUPREQ.line_description                        -- ���דE�v(�x���˗����IF����)
        ,FU_CB.user_name                                -- �쐬��
        ,TO_CHAR( SUPREQ.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                                        -- �쐬��(�x���˗����IF����)
        ,FU_LU.user_name                                -- �ŏI�X�V��
        ,TO_CHAR( SUPREQ.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                                        -- �ŏI�X�V��(�x���˗����IF����)
        ,FU_LL.user_name                                -- �ŏI�X�V���O�C��
  FROM
        -- ���̎擾�n�ȊO�̃f�[�^�͂��̓���SQL�őS�Ď擾����
        ( SELECT
                 XSRHI.corporation_name                 -- ��Ж�
                , XSRHI.data_class                      -- �f�[�^���
                , XSRHI.transfer_branch_no              -- �`���p�}��
                , XSRHI.trans_type                      -- �����敪
                , CASE XSRHI.trans_type                 -- �����敪��
                        WHEN 1 THEN '�x���˗�'
                        WHEN 2 THEN '�d���L��'
                  END trans_type_name
                , XSRHI.weight_capacity_class           -- �d�ʗe�ϋ敪
                , XSRHI.requested_department_code       -- �˗������R�[�h
                , XSRHI.instruction_post_code           -- �w�������R�[�h
                , XSRHI.vendor_code                     -- �����R�[�h
                , XSRHI.ship_to_code                    -- �z����R�[�h
                , XSRHI.shipped_locat_code              -- �o�ɑq�ɃR�[�h
                , XSRHI.freight_carrier_code            -- �^���Ǝ҃R�[�h
                , XSRHI.ship_date                       -- �o�ɓ�
                , XSRHI.arvl_date                       -- ���ɓ�
                , XSRHI.freight_charge_class            -- �^���敪
                , XSRHI.takeback_class                  -- ����敪
                , XSRHI.arrival_time_from               -- ���׎���FROM
                , XSRHI.arrival_time_to                 -- ���׎���TO
                , XSRHI.product_date                    -- ������
                , XSRHI.producted_item_code             -- �����i�ڃR�[�h
                , XSRHI.product_number                  -- �����ԍ�
                , XSRHI.header_description              -- �w�b�_�E�v
                , XSRLI.line_number                     -- ���הԍ�(�x���˗����IF����)
                , XSRLI.item_code                       -- �i�ڃR�[�h(�x���˗����IF����)
                , XSRLI.futai_code                      -- �t��(�x���˗����IF����)
                , XSRLI.request_qty                     -- �˗�����(�x���˗����IF����)
                , XSRLI.line_description                -- ���דE�v(�x���˗����IF����)
                , XSRLI.created_by                      -- �쐬��(�x���˗����IF����)
                , XSRLI.creation_date                   -- �쐬��(�x���˗����IF����)
                , XSRLI.last_updated_by                 -- �ŏI�X�V��(�x���˗����IF����)
                , XSRLI.last_update_date                -- �ŏI�X�V��(�x���˗����IF����)
                , XSRLI.last_update_login               -- �ŏI�X�V���O�C��(�x���˗����IF����)
        FROM
                 xxpo_supply_req_headers_if XSRHI       -- �x���˗����C���^�t�F�[�X�e�[�u���w�b�_
                ,xxpo_supply_req_lines_if   XSRLI       -- �x���˗����C���^�t�F�[�X�e�[�u������
        WHERE
                XSRHI.supply_req_headers_if_id  = XSRLI.supply_req_headers_if_id
        )                                   SUPREQ      -- �x���˗����w�b�_������
        -- �ȉ��͏�LSQL�����̍��ڂ��g�p���ĊO���������s������(�G���[�����)
        ,xxsky_locations2_v                 XL2V01      -- SKYLINK�p����VIEW ���Ə����VIEW2(�˗�������)
        ,xxsky_locations2_v                 XL2V02      -- SKYLINK�p����VIEW ���Ə����VIEW2(�w��������)
        ,xxsky_vendors2_v                   XV2V        -- SKYLINK�p����VIEW �d������VIEW2(����於)
        ,xxsky_party_sites2_v               XPS2V       -- SKYLINK�p����VIEW �z������VIEW2(�z���於)
        ,xxsky_item_locations_v             XILV        -- SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�ɑq�ɖ�)
        ,xxsky_carriers2_v                  XC2V        -- SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
        ,xxsky_item_mst2_v                  XIM2V01     -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�����i�ږ�)
        ,xxsky_item_mst2_v                  XIM2V02     -- SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ږ�)
        ,xxsky_prod_class_v                 XPCV        -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(���i�敪)
        ,xxsky_item_class_v                 XICV        -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�i�ڋ敪)
        ,xxsky_crowd_code_v                 XCCV        -- SKYLINK�p����VIEW OPM�i�ڋ敪VIEW(�Q�R�[�h)
        ,fnd_user                           FU_CB       -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
        ,fnd_user                           FU_LU       -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
        ,fnd_user                           FU_LL       -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_logins                         FL_LL       -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
        ,fnd_lookup_values                  FLV01       -- �N�C�b�N�R�[�h�\(�d�ʗe�ϋ敪��)
        ,fnd_lookup_values                  FLV02       -- �N�C�b�N�R�[�h�\(�^���敪��)
        ,fnd_lookup_values                  FLV03       -- �N�C�b�N�R�[�h�\(����敪��)
        ,fnd_lookup_values                  FLV04       -- �N�C�b�N�R�[�h�\(���׎���FROM��)
        ,fnd_lookup_values                  FLV05       -- �N�C�b�N�R�[�h�\(���׎���TO��)
 WHERE
   -- �d�ʗe�ϋ敪���擾
        FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV01.lookup_code(+)            = SUPREQ.weight_capacity_class
   -- �˗��������擾
   AND  XL2V01.location_code(+)         = SUPREQ.requested_department_code
   AND  XL2V01.start_date_active(+)     <= SUPREQ.arvl_date
   AND  XL2V01.end_date_active(+)       >= SUPREQ.arvl_date
   -- �w���������擾
   AND  XL2V02.location_code(+)         = SUPREQ.instruction_post_code
   AND  XL2V02.start_date_active(+)     <= SUPREQ.arvl_date
   AND  XL2V02.end_date_active(+)       >= SUPREQ.arvl_date
   -- ����於�擾
   AND  SUPREQ.vendor_code              = XV2V.segment1(+)
   AND  XV2V.start_date_active(+)       <= SUPREQ.arvl_date
   AND  XV2V.end_date_active(+)         >= SUPREQ.arvl_date
   -- �z���於�擾
   AND  SUPREQ.ship_to_code             = XPS2V.party_site_number(+)
   AND  XPS2V.start_date_active(+)      <= SUPREQ.arvl_date
   AND  XPS2V.end_date_active(+)        >= SUPREQ.arvl_date
   -- �o�ɑq�ɖ��擾
   AND  SUPREQ.shipped_locat_code       = XILV.segment1(+)
   -- �^���ƎҖ��擾
   AND  SUPREQ.freight_carrier_code     = XC2V.freight_code(+)
   AND  XC2V.start_date_active(+)       <= SUPREQ.arvl_date
   AND  XC2V.end_date_active(+)         >= SUPREQ.arvl_date
   -- �^���敪���擾
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV02.lookup_code(+)            = SUPREQ.freight_charge_class
   -- ����敪���擾
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXWSH_TAKEBACK_CLASS'
   AND  FLV03.lookup_code(+)            = SUPREQ.takeback_class
   -- ���׎��Ԗ��擾(FROM)
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV04.lookup_code(+)            = SUPREQ.arrival_time_from
   -- ���׎��Ԗ��擾(TO)
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXWSH_ARRIVAL_TIME'
   AND  FLV05.lookup_code(+)            = SUPREQ.arrival_time_to
   -- �����i�ږ��A�����i�ڗ��̎擾
   AND  XIM2V01.item_no(+)              = SUPREQ.producted_item_code
   AND  XIM2V01.start_date_active(+)    <= SUPREQ.arvl_date
   AND  XIM2V01.end_date_active(+)      >= SUPREQ.arvl_date
   -- ���i�敪�A���i�敪���擾
   AND  XIM2V02.item_id                 = XPCV.item_id(+)
   -- �i�ڋ敪�A�i�ڋ敪���擾
   AND  XIM2V02.item_id                 = XICV.item_id(+)
   -- �Q�R�[�h�擾
   AND  XIM2V02.item_id                 = XCCV.item_id(+)
   -- �i�ږ��A�i�ڗ��̎擾
   AND  XIM2V02.item_no(+)              = SUPREQ.item_code
   AND  XIM2V02.start_date_active(+)    <= SUPREQ.arvl_date
   AND  XIM2V02.end_date_active(+)      >= SUPREQ.arvl_date
   -- ���[�U���Ȃ�
   AND  SUPREQ.created_by               = FU_CB.user_id(+)
   AND  SUPREQ.last_updated_by          = FU_LU.user_id(+)
   AND  SUPREQ.last_update_login        = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�x���˗����IF_��{_V IS 'SKYLINK�p�x���˗����C���^�[�t�F�[�X�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.��Ж�           IS '��Ж�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�f�[�^���       IS '�f�[�^���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�`���p�}��       IS '�`���p�}��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����敪         IS '�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����敪��       IS '�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�d�ʗe�ϋ敪     IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�d�ʗe�ϋ敪��   IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�˗������R�[�h   IS '�˗������R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�˗�������       IS '�˗�������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�w�������R�[�h   IS '�w�������R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�w��������       IS '�w��������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����R�[�h     IS '�����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.����於         IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�z����R�[�h     IS '�z����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�z���於         IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�o�ɑq�ɃR�[�h   IS '�o�ɑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�o�ɑq�ɖ�       IS '�o�ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�^���Ǝ҃R�[�h   IS '�^���Ǝ҃R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�^���ƎҖ�       IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�o�ɓ�           IS '�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���ɓ�           IS '���ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�^���敪         IS '�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�^���敪��       IS '�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.����敪         IS '����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.����敪��       IS '����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���׎���FROM     IS '���׎���FROM'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���׎���FROM��   IS '���׎���FROM��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���׎���TO       IS '���׎���TO'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���׎���TO��     IS '���׎���TO��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.������           IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����i�ڃR�[�h   IS '�����i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����i�ږ�       IS '�����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����i�ڗ���     IS '�����i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�����ԍ�         IS '�����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�w�b�_�E�v       IS '�w�b�_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���הԍ�         IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���i�敪         IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���i�敪��       IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�i�ڋ敪         IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�i�ڋ敪��       IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�Q�R�[�h         IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�i�ڃR�[�h       IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�i�ږ�           IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�i�ڗ���         IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�t��             IS '�t��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�˗�����         IS '�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.���דE�v         IS '���דE�v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�쐬��           IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�ŏI�X�V��       IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���˗����IF_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
