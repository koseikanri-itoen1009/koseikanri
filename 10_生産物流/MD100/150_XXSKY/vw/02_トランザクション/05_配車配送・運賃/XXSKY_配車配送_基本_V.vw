CREATE OR REPLACE VIEW APPS.XXSKY_�z�Ԕz��_��{_V
(
 �������_�z��
,�������_�z�Ԗ�
,���ڎ��
,���ڎ�ʖ�
,�z��NO
,�����NO
,�^���Ǝ�
,�^���ƎҖ�
,�z����
,�z������
,�z����R�[�h�敪
,�z����R�[�h�敪��
,�z����
,�z���於
,�z���敪
,�z���敪��
,�o�Ɍ`��
,�����z�ԑΏۋ敪
,�����z�ԑΏۋ敪��
,�o�ɗ\���
,���ח\���
,�E�v
,�x���^���v�Z�Ώۃt���O
,�x���^���v�Z�Ώۃt���O��
,�����^���v�Z�Ώۃt���O
,�����^���v�Z�Ώۃt���O��
,�ύڏd�ʍ��v
,�ύڗe�ύ��v
,�d�ʐύڌ���
,�e�ϐύڌ���
,��{�d��
,��{�e��
,�^���Ǝ�_����
,�^���Ǝ�_���і�
,�z���敪_����
,�z���敪_���і�
,�o�ד�
,���ד�
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,�^���`��
,�^���`�Ԗ�
,�����NO
,������
,���x������
,���i�敪
,���i�敪��
,�`�[�Ȃ��z�ԋ敪
,�`�[�Ȃ��z�ԋ敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        XCS.transaction_type                                --�������_�z��
       ,FLV01.meaning           transaction_name            --�������_�z�Ԗ�
       ,XCS.mixed_type                                      --���ڎ��
       ,CASE XCS.mixed_type                                 --���ڎ�ʖ�
            WHEN    '1' THEN    '�W��'
            WHEN    '2' THEN    '����'
        END                     mixed_type_name
       ,XCS.delivery_no                                     --�z��No
       ,XCS.default_line_number                             --�����No
       ,XCS.carrier_code                                    --�^���Ǝ�
       ,XC2V01.party_name       carrier_name                --�^���ƎҖ�
       ,XCS.deliver_from                                    --�z����
       ,XIL2V.description       deliver_from_name           --�z������
       ,XCS.deliver_to_code_class                           --�z����R�[�h�敪
       ,FLV02.meaning           deliver_to_code_name        --�z����R�[�h�敪��
       ,XCS.deliver_to                                      --�z����
       ,DVTO.name               deliver_name                --�z���於
       ,XCS.delivery_type                                   --�z���敪
       ,FLV03.meaning           delivery_type_name          --�z���敪��
       ,OTTT.name               transaction_type_name       --�o�Ɍ`��
       ,XCS.auto_process_type                               --�����z�ԑΏۋ敪
       ,FLV04.meaning           auto_process_name           --�����z�ԑΏۋ敪��
       ,XCS.schedule_ship_date                              --�o�ɗ\���
       ,XCS.schedule_arrival_date                           --���ח\���
       ,XCS.description                                     --�E�v
       ,XCS.payment_freight_flag                            --�x���^���v�Z�Ώۃt���O
       ,CASE XCS.payment_freight_flag                       --�x���^���v�Z�Ώۃt���O��
            WHEN    '0' THEN    '�ΏۊO'
            WHEN    '1' THEN    '�Ώ�'
        END                     payment_freight_name
       ,XCS.demand_freight_flag                             --�����^���v�Z�Ώۃt���O
       ,CASE XCS.demand_freight_flag                        --�����^���v�Z�Ώۃt���O��
            WHEN    '0' THEN    '�ΏۊO'
            WHEN    '1' THEN    '�Ώ�'
        END                     demand_freight_name
       ,CEIL( XCS.sum_loading_weight   )                    --�ύڏd�ʍ��v(�����_��ȉ��؂�グ)
       ,CEIL( XCS.sum_loading_capacity )                    --�ύڗe�ύ��v(�����_��ȉ��؂�グ)
       ,CEIL( XCS.loading_efficiency_weight   * 100 ) / 100 --�d�ʐύڌ���(�����_��R�ʈȉ��؂�グ)
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100 --�e�ϐύڌ���(�����_��R�ʈȉ��؂�グ)
       ,XCS.based_weight                                    --��{�d��
       ,XCS.based_capacity                                  --��{�e��
       ,XCS.result_freight_carrier_code                     --�^���Ǝ�_����
       ,XC2V02.party_name       result_freight_carrier_name --�^���Ǝ�_���і�
       ,XCS.result_shipping_method_code                     --�z���敪_����
       ,FLV05.meaning           result_shipping_method_name --�z���敪_���і�
       ,XCS.shipped_date                                    --�o�ד�
       ,XCS.arrival_date                                    --���ד�
       ,XCS.weight_capacity_class                           --�d�ʗe�ϋ敪
       ,FLV06.meaning           weight_capacity_name        --�d�ʗe�ϋ敪��
       ,XCS.freight_charge_type                             --�^���`��
       ,FLV07.meaning           freight_charge_name         --�^���`�Ԗ�
       ,XCS.slip_number                                     --�����No
       ,XCS.small_quantity                                  --������
       ,XCS.label_quantity                                  --���x������
       ,XCS.prod_class                                      --���i�敪
       ,FLV08.meaning           prod_name                   --���i�敪��
       ,XCS.non_slip_class                                  --�`�[�Ȃ��z�ԋ敪
       ,CASE XCS.non_slip_class                             --�`�[�Ȃ��z�ԋ敪��
            WHEN    '1' THEN    '�ʏ�z��'
            WHEN    '2' THEN    '�`�[�Ȃ��z��'
            WHEN    '3' THEN    '�`�[�Ȃ��z�ԉ���'
        END                     non_slip_name
       ,FU_CB.user_name         created_by_name             --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XCS.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                creation_date               --�쐬����
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XCS.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                last_update_date            --�X�V����
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxwsh_carriers_schedule XCS                         --�z�Ԕz���v��A�h�I���C���^�t�F�[�X
       ,xxsky_carriers2_v       XC2V01                      --SKYLINK�p����VIEW �^���ƎҎ擾VIEW
       ,xxsky_carriers2_v       XC2V02                      --SKYLINK�p����VIEW �^���ƎҎ擾VIEW
       ,xxsky_item_locations2_v XIL2V                       --SKYLINK�p����VIEW �z�����擾VIEW
       ,(  -- �z���於�擾�p�i�z���於�擾�敪�̒l�ɂ���Ď擾�悪�قȂ�j
           -- �z���於�擾�敪��'1'�̏ꍇ�͔z���於���擾
           SELECT
                  1                      class   -- 1:�z����
                 ,party_site_id          id      -- �z����R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
                 ,party_site_number      code    -- �z����R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                 ,party_site_name        name    -- �z���於
                 ,start_date_active      dstart  -- �K�p�J�n��
                 ,end_date_active        dend    -- �K�p�I����
           FROM   xxsky_party_sites2_v           -- �z����
         UNION ALL
           -- �z���於�擾�敪��'2'�̏ꍇ��OPM�ۊǏꏊ�����擾
           SELECT
                  2                      class   -- 2:�ۊǏꏊ
                 ,inventory_location_id  id      -- �ۊǑq�ɃR�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
                 ,segment1               code      -- �ۊǑq�ɃR�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                 ,description            name    -- �ۊǑq�ɖ�
                 ,TO_DATE( '19000101', 'YYYYMMDD' )
                                         dstart  -- �K�p�J�n��
                 ,TO_DATE( '99991231', 'YYYYMMDD' )
                                         dend    -- �K�p�I����
           FROM  xxsky_item_locations_v          -- �ۊǑq��
         UNION ALL
           -- �z���於�擾�敪��'3'�̏ꍇ�͍H�ꖼ���擾
           SELECT
                  3                      class   -- 3:�H��
                 ,vendor_site_id         id      -- �����T�C�g�R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
                 ,vendor_site_code       code    -- �����T�C�g�R�[�h
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                 ,vendor_site_name       name    -- �����T�C�g��
                 ,start_date_active      dstart  -- �K�p�J�n��
                 ,end_date_active        dend    -- �K�p�I����
           FROM   xxsky_vendor_sites2_v          -- �d����T�C�gVIEW
        )                       DVTO                        --���__����於�擾�p
       ,oe_transaction_types_tl OTTT                        --�󒍃^�C�v���擾�p
       ,fnd_lookup_values       FLV01                       --�������_�z�Ԗ��擾�p
       ,fnd_lookup_values       FLV02                       --�z����R�[�h�敪���擾�p
       ,fnd_lookup_values       FLV03                       --�z���敪���擾�p
       ,fnd_lookup_values       FLV04                       --�����z�ԑΏۋ敪���擾�p
       ,fnd_lookup_values       FLV05                       --�z���敪_���і��擾�p
       ,fnd_lookup_values       FLV06                       --�d�ʗe�ϋ敪���擾�p
       ,fnd_lookup_values       FLV07                       --�^���`�Ԗ��擾�p
       ,fnd_lookup_values       FLV08                       --���i�敪���擾�p
       ,fnd_user                FU_CB                       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU                       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL                       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL                       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
    --�^���ƎҖ��擾����
        XC2V01.party_id(+)              =  XCS.carrier_id
   AND  XC2V01.start_date_active(+)     <= NVL(XCS.schedule_ship_date, SYSDATE)
   AND  XC2V01.end_date_active(+)       >= NVL(XCS.schedule_ship_date, SYSDATE)
    --�^���Ǝ�_���і��擾����
   AND  XC2V02.party_id(+)              =  XCS.result_freight_carrier_id
   AND  XC2V02.start_date_active(+)     <= NVL(XCS.schedule_ship_date, SYSDATE)
   AND  XC2V02.end_date_active(+)       >= NVL(XCS.schedule_ship_date, SYSDATE)
    --�z�������擾����
   AND  XIL2V.inventory_location_id(+)  =  XCS.deliver_from_id
    --�z���於�擾����
   AND  DECODE( XCS.deliver_to_code_class
              , '1' , '1'     -- 1:���_     �� 1:�z����}�X�^���疼�̎擾
              , '2' , '1'     -- 2:����     �� 1:�z����}�X�^���疼�̎擾
              , '3' , '2'     -- 3:�q��     �� 2:�ۊǏꏊ�}�X�^���疼�̎擾
              , '4' , '2'     -- 4:�q�ɉ�� �� 2:�ۊǏꏊ�}�X�^���疼�̎擾
              , '5' , '3'     -- 5:�p�b�J�[ �� 3:�d����T�C�g�}�X�^���疼�̎擾
              , '6' , '3'     -- 6:���Y�H�� �� 3:�d����T�C�g�}�X�^���疼�̎擾
              , '7' , '1'     -- 7:�^���Ǝ� �� 1:�z����}�X�^���疼�̎擾
              , '8' , '3'     -- 8:�����   �� 3:�d����T�C�g�}�X�^���疼�̎擾
              , '9' , '1'     -- 9:�z����   �� 1:�z����}�X�^���疼�̎擾
              , '10', '1'     --10:�ڋq     �� 1:�z����}�X�^���疼�̎擾
              , '11', '3'     --11:�x����   �� 3:�d����T�C�g�}�X�^���疼�̎擾
              , NULL ) = DVTO.class(+)
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
-- �ꗥ�R�[�h�ɂČ���
--   AND  XCS.deliver_to_id = DVTO.id(+)
   AND  XCS.deliver_to    = DVTO.code(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
   AND  NVL( XCS.schedule_ship_date, SYSDATE ) >= DVTO.dstart(+)
   AND  NVL( XCS.schedule_ship_date, SYSDATE ) <= DVTO.dend(+)
    --�󒍃^�C�v��(�o�Ɍ`��)�擾����
   AND  OTTT.language(+)                = 'JA'
   AND  OTTT.transaction_type_id(+)     = XCS.order_type_id
    --�������_�z�Ԗ��擾����
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXWSH_PROCESS_TYPE'
   AND  FLV01.lookup_code(+)            = XCS.transaction_type
   --�z����R�[�h�敪���擾����
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'CUSTOMER CLASS'
   AND  FLV02.lookup_code(+)            = XCS.deliver_to_code_class
    --�z���敪���擾����
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV03.lookup_code(+)            = XCS.delivery_type
   --�����z�ԑΏۋ敪���擾����
   AND  FLV04.language(+)               = 'JA'
   AND  FLV04.lookup_type(+)            = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV04.lookup_code(+)            = XCS.auto_process_type
    --�z���敪_���і��擾����
   AND  FLV05.language(+)               = 'JA'
   AND  FLV05.lookup_type(+)            = 'XXCMN_SHIP_METHOD'
   AND  FLV05.lookup_code(+)            = XCS.result_shipping_method_code
   --�d�ʗe�ϋ敪���擾����
   AND  FLV06.language(+)               = 'JA'
   AND  FLV06.lookup_type(+)            = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV06.lookup_code(+)            = XCS.weight_capacity_class
    --�^���`�Ԗ��擾����
   AND  FLV07.language(+)               = 'JA'
   AND  FLV07.lookup_type(+)            = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV07.lookup_code(+)            = XCS.freight_charge_type
   --���i�敪���擾����
   AND  FLV08.language(+)               = 'JA'
   AND  FLV08.lookup_type(+)            = 'XXWIP_ITEM_TYPE'
   AND  FLV08.lookup_code(+)            = XCS.prod_class
   --WHO�J�����擾
   AND  XCS.created_by                  = FU_CB.user_id(+)
   AND  XCS.last_updated_by             = FU_LU.user_id(+)
   AND  XCS.last_update_login           = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�z�Ԕz��_��{_V                             IS 'SKYLINK�p�z�Ԕz���i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�������_�z��              IS '�������_�z��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�������_�z�Ԗ�            IS '�������_�z�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���ڎ��                   IS '���ڎ��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���ڎ�ʖ�                 IS '���ڎ�ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z��NO                     IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�����NO                 IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�^���Ǝ�                   IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�^���ƎҖ�                 IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z����                     IS '�z����'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z������                   IS '�z������'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z����R�[�h�敪           IS '�z����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z����R�[�h�敪��         IS '�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z����                     IS '�z����'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z���於                   IS '�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z���敪                   IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z���敪��                 IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�o�Ɍ`��                   IS '�o�Ɍ`��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�����z�ԑΏۋ敪           IS '�����z�ԑΏۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�����z�ԑΏۋ敪��         IS '�����z�ԑΏۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�o�ɗ\���                 IS '�o�ɗ\���'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���ח\���                 IS '���ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�E�v                       IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�x���^���v�Z�Ώۃt���O     IS '�x���^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�x���^���v�Z�Ώۃt���O��   IS '�x���^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�����^���v�Z�Ώۃt���O     IS '�����^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�����^���v�Z�Ώۃt���O��   IS '�����^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�ύڏd�ʍ��v               IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�ύڗe�ύ��v               IS '�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�d�ʐύڌ���               IS '�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�e�ϐύڌ���               IS '�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.��{�d��                   IS '��{�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.��{�e��                   IS '��{�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�^���Ǝ�_����              IS '�^���Ǝ�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�^���Ǝ�_���і�            IS '�^���Ǝ�_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z���敪_����              IS '�z���敪_����'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�z���敪_���і�            IS '�z���敪_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�o�ד�                     IS '�o�ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���ד�                     IS '���ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�d�ʗe�ϋ敪               IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�d�ʗe�ϋ敪��             IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�^���`��                   IS '�^���`��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�^���`�Ԗ�                 IS '�^���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�����NO                   IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.������                   IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���x������                 IS '���x������'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���i�敪                   IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.���i�敪��                 IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�`�[�Ȃ��z�ԋ敪           IS '�`�[�Ȃ��z�ԋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�`�[�Ȃ��z�ԋ敪��         IS '�`�[�Ȃ��z�ԋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�쐬��                     IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�쐬��                     IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�ŏI�X�V��                 IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�ŏI�X�V��                 IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�z�Ԕz��_��{_V.�ŏI�X�V���O�C��           IS '�ŏI�X�V���O�C��'
/
