/*************************************************************************
 * 
 * View  Name      : XXSKZ_�i�������˗����_��{_V
 * Description     : XXSKZ_�i�������˗����_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�i�������˗����_��{_V
(
 �����˗�NO
,�������
,������ʖ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,���b�gNO
,�敪
,�敪��
,�d����R�[�h
,�d���於
,���C��NO
,���C����
,������
,�ŗL�L��
,�ܖ�����
,��������
,����
,�[����
,�����\����P
,�������P
,���ʂP
,���ʖ��P
,�����\����Q
,�������Q
,���ʂQ
,���ʖ��Q
,�����\����R
,�������R
,���ʂR
,���ʖ��R
,���l
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XQI.qt_inspect_req_no                               --�����˗�No
       ,XQI.inspect_class                                   --�������
       ,CASE XQI.inspect_class                              --������ʖ�
            WHEN    '1' THEN    '���Y'
            WHEN    '2' THEN    '�����d��'
        END                     inspect_name
       ,XPCV.prod_class_code                                --���i�敪
       ,XPCV.prod_class_name                                --���i�敪��
       ,XICV.item_class_code                                --�i�ڋ敪
       ,XICV.item_class_name                                --�i�ڋ敪��
       ,XCCV.crowd_code                                     --�Q�R�[�h
       ,XIM2V.item_no                                       --�i�ڃR�[�h
       ,XIM2V.item_name                                     --�i�ږ�
       ,XIM2V.item_short_name                               --�i�ڗ���
       ,ILM.lot_no                                          --���b�gNo
       ,XQI.division                                        --�敪
       ,CASE XQI.division                                   --�敪��
            WHEN    '1' THEN    '���Y'
            WHEN    '2' THEN    '����'
            WHEN    '3' THEN    '���b�g���'
            WHEN    '4' THEN    '�O���o����'
            WHEN    '5' THEN    '�r������'
        END                     division_name
       ,CASE XQI.division                                   --�d����R�[�h
            WHEN    '1' THEN    NULL
            ELSE                XQI.vendor_line
        END                     vendor_line
       ,CASE XQI.division                                   --�d���於
            WHEN    '1' THEN    NULL
            ELSE                XV2V.vendor_name
        END                     vendor_name
       ,CASE XQI.division                                   --���C��No
            WHEN    '1' THEN    XQI.vendor_line
            ELSE                NULL
        END                     line_no
       ,CASE XQI.division                                   --���C����
            WHEN    '1' THEN    GRT.routing_desc
            ELSE                NULL
        END                     line_name
       ,ILM.attribute1                                      --������
       ,ILM.attribute2                                      --�ŗL�L��
       ,ILM.attribute3                                      --�ܖ�����
       ,XQI.inspect_period                                  --��������
       ,XQI.qty                                             --���ʓ�
       ,XQI.prod_dely_date                                  --�[����
       ,XQI.inspect_due_date1                               --�����\����P
       ,XQI.test_date1                                      --�������P
       ,XQI.qt_effect1                                      --���ʂP
       ,FLV01.meaning           qt_effect_name1             --���ʖ��P�Q
       ,XQI.inspect_due_date2                               --�����\����Q
       ,XQI.test_date2                                      --�������Q
       ,XQI.qt_effect2                                      --���ʂQ
       ,FLV02.meaning           qt_effect_name2             --���ʖ��Q�R
       ,XQI.inspect_due_date3                               --�����\����R
       ,XQI.test_date3                                      --�������R
       ,XQI.qt_effect3                                      --���ʂR
       ,FLV03.meaning           qt_effect_name3             --���ʖ��R
       ,ILM.attribute18                                     --���l
       ,FU_CB.user_name         created_by_name             --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XQI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date               --�쐬����
       ,FU_LU.user_name         last_updated_by_name        --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XQI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date            --�X�V����
       ,FU_LL.user_name         last_update_login_name      --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxwip_qt_inspection     XQI                         --�i�������˗����A�h�I��
       ,xxskz_prod_class_v      XPCV                        --SKYLINK�p����VIEW ���i�敪�擾VIEW
       ,xxskz_item_class_v      XICV                        --SKYLINK�p����VIEW �i�ڏ��i�敪�擾VIEW
       ,xxskz_crowd_code_v      XCCV                        --SKYLINK�p����VIEW �Q�R�[�h�擾VIEW
       ,xxskz_item_mst2_v       XIM2V                       --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2
       ,ic_lots_mst             ILM                         --���b�gNo�擾�p
       ,xxskz_vendors2_v        XV2V                        --SKYLINK�p����VIEW �d����擾VIEW
       ,gmd_routings_b          GRB                         --���C�����擾�p
       ,gmd_routings_tl         GRT                         --���C�����擾�p
       ,fnd_lookup_values       FLV01                       --���ʖ��P�擾�p
       ,fnd_lookup_values       FLV02                       --���ʖ��Q�擾�p
       ,fnd_lookup_values       FLV03                       --���ʖ��R���擾�p
       ,fnd_user                FU_CB                       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU                       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL                       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL                       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE
    --�i�ڃR�[�h�A�i�ږ��A�i�ڗ��̎擾����
        XIM2V.item_id(+)            =  XQI.item_id
   AND  XIM2V.start_date_active(+)  <= NVL(XQI.product_date, TRUNC(SYSDATE))
   AND  XIM2V.end_date_active(+)    >= NVL(XQI.product_date, TRUNC(SYSDATE))
    --���i�敪�A���i�敪���擾����
   AND  XPCV.item_id(+)             =  XQI.item_id
    --�i�ڋ敪�A�i�ڋ敪���擾����
   AND  XICV.item_id(+)             =  XQI.item_id
    --�Q�R�[�h�擾����
   AND  XCCV.item_id(+)             =  XQI.item_id
    --���b�gNo�擾����
   AND  ILM.item_id(+)              =  XQI.item_id
   AND  ILM.lot_id(+)               =  XQI.lot_id
    --�d���於�擾����
   AND  XV2V.segment1(+)            =  XQI.vendor_line
   AND  XV2V.start_date_active(+)   <= NVL(XQI.product_date, TRUNC(SYSDATE))
   AND  XV2V.end_date_active(+)     >= NVL(XQI.product_date, TRUNC(SYSDATE))
    --���C�����擾����
   AND  GRB.routing_no(+)           =  XQI.vendor_line
   AND  GRB.routing_vers(+)         =  1
   AND  GRT.language(+)             =  'JA'
   AND  GRT.routing_id(+)           =  GRB.routing_id
    --���ʖ��P�擾����
   AND  FLV01.language(+)           = 'JA'
   AND  FLV01.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV01.lookup_code(+)        = XQI.qt_effect1
    --���ʖ��Q�擾����
   AND  FLV02.language(+)           = 'JA'
   AND  FLV02.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV02.lookup_code(+)        = XQI.qt_effect2
    --���ʖ��R�擾����
   AND  FLV03.language(+)           = 'JA'
   AND  FLV03.lookup_type(+)        = 'XXWIP_QT_STATUS'
   AND  FLV03.lookup_code(+)        = XQI.qt_effect3
   --WHO�J�����擾
   AND  XQI.created_by              = FU_CB.user_id(+)
   AND  XQI.last_updated_by         = FU_LU.user_id(+)
   AND  XQI.last_update_login       = FL_LL.login_id(+)
   AND  FL_LL.user_id               = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�i�������˗����_��{_V IS 'SKYLINK�p�i�������˗����i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�����˗�NO IS '�����˗�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.������� IS '�������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.������ʖ� IS '������ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�i�ږ� IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���b�gNO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�敪 IS '�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�敪�� IS '�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�d����R�[�h IS '�d����R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�d���於 IS '�d���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���C��NO IS '���C��No'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���C���� IS '���C����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�������� IS '��������'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���� IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�[���� IS '�[����'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�����\����P IS '�����\����P'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�������P IS '�������P'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���ʂP IS '���ʂP'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���ʖ��P IS '���ʖ��P'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�����\����Q IS '�����\����Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�������Q IS '�������Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���ʂQ IS '���ʂQ'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���ʖ��Q IS '���ʖ��Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�����\����R IS '�����\����R'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�������R IS '�������R'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���ʂR IS '���ʂR'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���ʖ��R IS '���ʖ��R'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.���l IS '���l'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�i�������˗����_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
