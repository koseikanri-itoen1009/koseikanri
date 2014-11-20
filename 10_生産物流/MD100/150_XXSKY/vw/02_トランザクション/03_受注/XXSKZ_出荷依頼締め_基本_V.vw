/*************************************************************************
 * 
 * View  Name      : XXSKZ_�o�׈˗�����_��{_V
 * Description     : XXSKZ_�o�׈˗�����_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/22    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�o�׈˗�����_��{_V
(
 ���߃R���J�����gID
,�󒍃^�C�v
,�o�׌��ۊǏꏊ
,�o�׌��ۊǏꏊ��
,���i�敪
,���i�敪��
,���_
,���_��
,���_�J�e�S��
,���_�J�e�S����
,���Y����LT
,�o�ח\���
,����_�����敪
,����_�����敪��
,���ߎ��{����
,����R�[�h�敪
,����R�[�h�敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        XTC.concurrent_id                                       --���߃R���J�����gID
       ,CASE XTC.order_type_id                                  --�󒍃^�C�v
            WHEN    -999    THEN    'ALL'
            ELSE                    OTTT.name
        END                         transaction_type_name
       ,XTC.deliver_from                                        --�o�׌��ۊǏꏊ
       ,XILV.description            deliver_from_name           --�o�׌��ۊǏꏊ��
       ,XTC.prod_class                                          --���i�敪
       ,FLV01.meaning               prod_class_name             --���i�敪��
       ,XTC.sales_branch                                        --���_
       ,XCA2V.party_name            sales_branch_name           --���_��
       ,XTC.sales_branch_category                               --���_�J�e�S��
       ,FLV02.meaning               sales_branch_category_name  --���_�J�e�S����
       ,CASE XTC.lead_time_day                                  --�󒍃^�C�v
            WHEN    -999    THEN    'ALL'                       --���Y����LT
            ELSE                    TO_CHAR(XTC.lead_time_day, 'FM9999')
        END                         lead_time_day
       ,XTC.schedule_ship_date                                  --�o�ח\���
       ,XTC.tighten_release_class                               --����_�����敪
       ,FLV03.meaning               tighten_release_class_name  --����_�����敪��
       ,TO_CHAR( XTC.tightening_date, 'YYYY/MM/DD HH24:MI:SS')
                                                                --���ߎ��{����
       ,XTC.base_record_class                                   --����R�[�h�敪
       ,CASE XTC.base_record_class                              --����R�[�h�敪��
            WHEN    'Y' THEN    '����R�[�h'
            WHEN    'N' THEN    '����ȊO'
        END                         base_record_class_name
       ,FU_CB.user_name             created_by_name             --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XTC.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                    creation_date               --�쐬����
       ,FU_LU.user_name             last_updated_by_name        --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XTC.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                    last_update_date            --�X�V����
       ,FU_LL.user_name             last_update_login_name      --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxwsh_tightening_control    XTC                         --�o�׈˗����ߊǗ��i�A�h�I���j
       ,oe_transaction_types_tl     OTTT                        --�󒍃^�C�v���擾�p
       ,xxskz_item_locations_v      XILV                        --SKYLINK�p����VIEW �o�׌��ۊǏꏊ���擾VIEW
       ,xxskz_cust_accounts2_v      XCA2V                       --SKYLINK�p����VIEW ���_���擾VIEW
       ,fnd_lookup_values           FLV01                       --���i�敪���擾�p
       ,fnd_lookup_values           FLV02                       --���_�J�e�S�����擾�p
       ,fnd_lookup_values           FLV03                       --����_�����敪���擾�p
       ,fnd_user                    FU_CB                       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                    FU_LU                       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                    FU_LL                       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                  FL_LL                       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
    --�󒍃^�C�v��(�o�Ɍ`��)�擾����
        OTTT.language(+)            = 'JA'
   AND  OTTT.transaction_type_id(+) =  XTC.order_type_id
    --�o�׌��ۊǏꏊ���擾����
   AND  XILV.segment1(+)            =  XTC.deliver_from
    --���_���擾����
   AND  XCA2V.party_number(+)       =  XTC.sales_branch
   AND  XCA2V.start_date_active(+)  <= XTC.tightening_date
   AND  XCA2V.end_date_active(+)    >= XTC.tightening_date
    --���i�敪���擾����
   AND  FLV01.language(+)           =  'JA'
   AND  FLV01.lookup_type(+)        =  'XXWIP_ITEM_TYPE'
   AND  FLV01.lookup_code(+)        =  XTC.prod_class
   --���_�J�e�S�����擾����
   AND  FLV02.language(+)           =  'JA'
   AND  FLV02.lookup_type(+)        =  'XXWSH_DRINK_BASE_CATEGORY'
   AND  FLV02.lookup_code(+)        =  XTC.sales_branch_category
    --����_�����敪���擾����
   AND  FLV03.language(+)           =  'JA'
   AND  FLV03.lookup_type(+)        =  'XXWSH_TIGHTEN_RELEASE_CLASS'
   AND  FLV03.lookup_code(+)        =  XTC.tighten_release_class
   --WHO�J�����擾
   AND  XTC.created_by              =  FU_CB.user_id(+)
   AND  XTC.last_updated_by         =  FU_LU.user_id(+)
   AND  XTC.last_update_login       =  FL_LL.login_id(+)
   AND  FL_LL.user_id               =  FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�o�׈˗�����_��{_V                     IS 'SKYLINK�p�o�׈˗����߁i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���߃R���J�����gID IS '���߃R���J�����gID'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�󒍃^�C�v         IS '�󒍃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�o�׌��ۊǏꏊ     IS '�o�׌��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�o�׌��ۊǏꏊ��   IS '�o�׌��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���i�敪           IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���i�敪��         IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���_               IS '���_'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���_��             IS '���_��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���_�J�e�S��       IS '���_�J�e�S��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���_�J�e�S����     IS '���_�J�e�S����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���Y����LT         IS '���Y����LT'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�o�ח\���         IS '�o�ח\���'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.����_�����敪      IS '����_�����敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.����_�����敪��    IS '����_�����敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.���ߎ��{����       IS '���ߎ��{����'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.����R�[�h�敪   IS '����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.����R�[�h�敪�� IS '����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�o�׈˗�����_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/                                                                       
